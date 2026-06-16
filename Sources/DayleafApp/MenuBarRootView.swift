import AppKit
import DayleafCore
import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    @FocusState private var focusedField: FocusedField?

    @State private var toastText: String?
    @State private var toastIsError = false
    @State private var toastTask: Task<Void, Never>?
    @State private var showingAbout = false
    @State private var showingSettings = false
    @State private var quickNoteFocused = false
    @State private var plannedHovered = false
    @State private var finishHovered = false
    @State private var quickNoteHovered = false

    @AppStorage(AppThemeStore.key) private var themeRaw = AppThemeStore.default
    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sectionGap) {
            header
            focusSection
            quickNoteSection
            timelineSection
            footer
        }
        .padding(DS.pagePadding)
        .frame(width: DS.popoverWidth)
        .background(Palette.background)
        .overlay(alignment: .top) {
            if let toastText {
                ToastView(text: toastText, isError: toastIsError)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .themedWindow(theme.colorScheme)
    }

    // MARK: - Toast

    private func presentToast(_ message: String?) {
        guard let message, message.isEmpty == false else { return }
        let (text, isError) = Self.toastContent(for: message)

        toastTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            toastText = text
            toastIsError = isError
        }

        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.25)) {
                toastText = nil
            }
        }
    }

    private static func toastContent(for message: String) -> (String, Bool) {
        let errorMarkers = ["失败", "不能", "需要", "先写", "已有", "无法"]
        let isError = errorMarkers.contains { message.contains($0) }
        // 导出成功只显示「已导出」，路径太长不进 toast
        let text = message.hasPrefix("已导出") ? "已导出" : message
        return (text, isError)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("一日一笺")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                Text(viewModel.now.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Button {
                viewModel.copyTodayForAI()
                presentToast(viewModel.statusMessage)
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
            .buttonStyle(IconButtonStyle())
            .help("复制今天的记录给 AI")
            .accessibilityLabel("复制给 AI")
        }
    }

    // MARK: - Focus

    @ViewBuilder
    private var focusSection: some View {
        if let session = viewModel.activeSession {
            activeFocusCard(session)
        } else {
            idleFocusCard
        }
    }

    private func activeFocusCard(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: DS.cardGap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(session.isPaused ? Palette.warn : Palette.accentText)
                    .frame(width: 7, height: 7)
                Text(session.isPaused ? "已暂停" : "专注中")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(session.isPaused ? Palette.warn : Palette.accentText)
            }

            Text(MarkdownExporter.durationText(session.activeDurationSeconds))
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(session.isPaused ? Palette.textSecondary : Palette.textPrimary)
                .contentTransition(.numericText())
                .animation(.default, value: session.activeDurationSeconds)

            if let planned = session.plannedActivity, planned.isEmpty == false {
                Text(planned)
                    .font(.callout)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }

            TextField("结束前记录实际做了什么", text: $viewModel.finishActivityDraft)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .softField(focused: focusedField == .finishActivity || finishHovered, elevated: true)
                .onHover { finishHovered = $0 }
                .submitLabel(.done)
                .focused($focusedField, equals: .finishActivity)
                .onSubmit {
                    let ok = viewModel.finishFocus()
                    presentToast(viewModel.statusMessage)
                    focusedField = ok ? .quickNote : .finishActivity
                }

            HStack(spacing: 8) {
                Button {
                    session.isPaused ? viewModel.resumeFocus() : viewModel.pauseFocus()
                    presentToast(viewModel.statusMessage)
                } label: {
                    Label(session.isPaused ? "继续" : "暂停",
                          systemImage: session.isPaused ? "play.fill" : "pause.fill")
                }
                .buttonStyle(NeutralButtonStyle(expand: false))

                Button {
                    _ = viewModel.finishFocus()
                    presentToast(viewModel.statusMessage)
                } label: {
                    Label("结束并保存", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(DS.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tile()
    }

    private var idleFocusCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(title: "专注")
            TextField("计划做什么，可不填", text: $viewModel.plannedActivityDraft)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .softField(focused: focusedField == .plannedActivity || plannedHovered)
                .onHover { plannedHovered = $0 }
                .submitLabel(.go)
                .focused($focusedField, equals: .plannedActivity)
                .onSubmit {
                    if viewModel.startFocus() {
                        presentToast(viewModel.statusMessage)
                        focusedField = .finishActivity
                    }
                }
            Button {
                if viewModel.startFocus() {
                    presentToast(viewModel.statusMessage)
                }
            } label: {
                Label("开始专注", systemImage: "play.fill")
            }
            .buttonStyle(NeutralButtonStyle())
        }
    }

    // MARK: - Quick Note

    private var quickNoteSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(title: "快速记录")
            QuickNoteEditor(
                text: $viewModel.quickNoteDraft,
                placeholder: "灵感、碎碎念、临时备注（回车保存，Shift+回车换行）",
                onSubmit: {
                    _ = viewModel.addQuickNote()
                    presentToast(viewModel.statusMessage)
                },
                onFocusChange: { quickNoteFocused = $0 }
            )
            .frame(height: 58)
            .softField(focused: quickNoteFocused || quickNoteHovered, tint: Palette.note)
            .onHover { quickNoteHovered = $0 }

            Button {
                if viewModel.addQuickNote() {
                    presentToast(viewModel.statusMessage)
                    focusedField = .quickNote
                } else {
                    presentToast(viewModel.statusMessage)
                }
            } label: {
                Label("记录一条", systemImage: "plus")
            }
            .buttonStyle(NeutralButtonStyle())
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeader(
                title: "今日时间线",
                trailing: viewModel.todayEntriesNewestFirst.isEmpty
                    ? nil
                    : "\(viewModel.todayEntriesNewestFirst.count) 条"
            )

            if viewModel.todayEntriesNewestFirst.isEmpty {
                emptyTimeline
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DS.rowGap) {
                        ForEach(viewModel.todayEntriesNewestFirst) { entry in
                            TimelineRow(
                                entry: entry,
                                now: viewModel.now,
                                onSave: {
                                    viewModel.updateEntryText(entry, to: $0)
                                    presentToast(viewModel.statusMessage)
                                },
                                onDelete: {
                                    viewModel.deleteEntry(entry)
                                    presentToast(viewModel.statusMessage)
                                }
                            )
                        }
                    }
                    .padding(.bottom, 2)
                }
                .frame(minHeight: 120, maxHeight: 220)
            }
        }
    }

    private var emptyTimeline: some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf")
                .font(.title3)
                .foregroundStyle(Palette.textTertiary)
            Text("今天还没有记录")
                .font(.callout)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .tile()
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Palette.separator)
                .frame(height: DS.hairline)

            HStack(alignment: .center, spacing: 4) {
                Button {
                    showingSettings = true
                } label: {
                    Label("设置", systemImage: "gearshape")
                }
                .buttonStyle(FooterButtonStyle())
                .help("保存目录、主题等设置")
                .popover(isPresented: $showingSettings, arrowEdge: .bottom) {
                    SettingsPanel(onStatusMessage: presentToast)
                        .environmentObject(viewModel)
                }

                Button {
                    showingAbout = true
                } label: {
                    Label("关于", systemImage: "info.circle")
                }
                .buttonStyle(FooterButtonStyle())
                .help("版本与隐私说明")
                .popover(isPresented: $showingAbout, arrowEdge: .bottom) {
                    AboutView()
                }

                Spacer(minLength: 4)

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(IconButtonStyle(size: 13))
                .keyboardShortcut("q", modifiers: .command)
                .help("退出一日一笺")
                .accessibilityLabel("退出一日一笺")
            }
        }
    }
}

// MARK: - Settings Panel

private struct SettingsPanel: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    @AppStorage(AppThemeStore.key) private var themeRaw = AppThemeStore.default
    let onStatusMessage: (String?) -> Void

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)

            VStack(alignment: .leading, spacing: 7) {
                Text("主题")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                Picker("主题", selection: $themeRaw) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("保存目录")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                Text(viewModel.exportDirectoryDisplay)
                    .font(.callout)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .tile(radius: DS.controlRadius)
                VStack(spacing: 8) {
                    Button {
                        viewModel.chooseExportDirectory()
                        onStatusMessage(viewModel.statusMessage)
                    } label: {
                        Label("选择目录…", systemImage: "folder")
                    }
                    .buttonStyle(NeutralButtonStyle())

                    Button {
                        viewModel.saveTodayPDF()
                        onStatusMessage(viewModel.statusMessage)
                    } label: {
                        Label("保存为 PDF", systemImage: "doc.richtext")
                    }
                    .buttonStyle(NeutralButtonStyle())
                }
                Text("需要归档时，可以把今天的记录保存成 PDF。")
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(width: 300)
        .background(Palette.background)
        .themedWindow(theme.colorScheme)
    }
}

// MARK: - About

private struct AboutView: View {
    @AppStorage(AppThemeStore.key) private var themeRaw = AppThemeStore.default
    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.accentText)
                VStack(alignment: .leading, spacing: 2) {
                    Text("一日一笺 · Dayleaf")
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Text("版本 \(Self.appVersion)")
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
            }

            Rectangle()
                .fill(Palette.separator)
                .frame(height: DS.hairline)

            VStack(alignment: .leading, spacing: 7) {
                Label("隐私为先 · 本地为先", systemImage: "lock.shield")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accentText)
                Text("你的所有记录只保存在这台电脑上：不上传、不联网、不做云同步，也不会被拿去分析。一日一笺只是一个属于你自己的本地日记夹。")
                    .font(.callout)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(width: 300)
        .background(Palette.background)
        .themedWindow(theme.colorScheme)
    }

    private static var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.3"
    }
}

private enum FocusedField: Hashable {
    case plannedActivity
    case finishActivity
    case quickNote
}

// MARK: - Timeline Row

private struct TimelineRow: View {
    let entry: DayEntry
    let now: Date
    let onSave: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var draft = ""
    @State private var confirmingDelete = false
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(typeColor)
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(typeTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(typeColor)
                    Text(timeSummary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.textTertiary)
                    Spacer(minLength: 4)
                    if canEdit && (isHovering || isEditing || confirmingDelete) {
                        actionMenu
                    }
                }

                if isEditing {
                    editor
                } else {
                    Text(content)
                        .font(.callout)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(2)
                    }
                }

                if confirmingDelete {
                    deleteConfirm
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tile(radius: DS.controlRadius, fill: isHovering ? Palette.control : Palette.tile)
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .onHover { isHovering = $0 }
    }

    // 进行中的专注不允许编辑/删除
    private var canEdit: Bool {
        if case .focusSession(let session) = entry {
            return session.endedAt != nil
        }
        return true
    }

    private var editableText: String {
        switch entry {
        case .focusSession(let session):
            return session.actualActivity
        case .quickNote(let note):
            return note.content
        }
    }

    private var actionMenu: some View {
        Menu {
            Button {
                draft = editableText
                confirmingDelete = false
                isEditing = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            Button(role: .destructive) {
                isEditing = false
                confirmingDelete = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("修改内容", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .softField(elevated: true)
                .lineLimit(1...4)
                .onSubmit { commitEdit() }
            HStack(spacing: 8) {
                Spacer()
                Button("取消") { isEditing = false }
                    .buttonStyle(NeutralButtonStyle(expand: false))
                Button("保存") { commitEdit() }
                    .buttonStyle(PrimaryButtonStyle(expand: false))
            }
        }
    }

    private var deleteConfirm: some View {
        HStack(spacing: 8) {
            Text("确认删除这条记录？")
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
            Spacer()
            Button("取消") { confirmingDelete = false }
                .buttonStyle(NeutralButtonStyle(expand: false))
            Button("删除") {
                confirmingDelete = false
                onDelete()
            }
            .buttonStyle(NeutralButtonStyle(fill: Palette.dangerFill, textColor: Palette.danger, expand: false))
        }
    }

    private func commitEdit() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        isEditing = false
        onSave(text)
    }

    private var typeTitle: String {
        switch entry {
        case .focusSession:
            "专注"
        case .quickNote:
            "记录"
        }
    }

    private var typeColor: Color {
        switch entry {
        case .focusSession:
            Palette.accentText
        case .quickNote:
            Palette.note
        }
    }

    private var timeSummary: String {
        switch entry {
        case .focusSession(let session):
            let start = session.startedAt.formatted(date: .omitted, time: .shortened)
            let end = (session.endedAt ?? now).formatted(date: .omitted, time: .shortened)
            return "\(start)-\(end)"
        case .quickNote(let note):
            return note.occurredAt.formatted(date: .omitted, time: .standard)
        }
    }

    private var content: String {
        switch entry {
        case .focusSession(let session):
            if session.actualActivity.isEmpty == false {
                return session.actualActivity
            }
            return session.plannedActivity ?? "进行中的专注"
        case .quickNote(let note):
            return note.content
        }
    }

    private var detail: String? {
        switch entry {
        case .focusSession(let session):
            let duration = MarkdownExporter.durationText(session.activeDuration(until: now))
            if let plannedActivity = session.plannedActivity, session.actualActivity.isEmpty == false {
                return "计划：\(plannedActivity) · 有效专注 \(duration)"
            }
            return "有效专注 \(duration)"
        case .quickNote(let note):
            return "时间戳：\(note.occurredAt.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeZone(separator: .colon)))"
        }
    }
}
