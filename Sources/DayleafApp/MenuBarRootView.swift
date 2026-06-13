import AppKit
import DayleafCore
import SwiftUI

struct MenuBarRootView: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            focusSection
            Divider()
            quickNoteSection
            Divider()
            timelineSection
            footer
        }
        .padding(14)
        .frame(width: 390)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("一日一笺")
                    .font(.headline)
                Text(viewModel.now.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                viewModel.exportToday()
            } label: {
                Label("导出", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var focusSection: some View {
        if let session = viewModel.activeSession {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(session.isPaused ? "已暂停" : "专注中", systemImage: session.isPaused ? "pause.circle" : "timer")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(MarkdownExporter.durationText(session.activeDurationSeconds))
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                }

                if let planned = session.plannedActivity {
                    Text(planned)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Button {
                        session.isPaused ? viewModel.resumeFocus() : viewModel.pauseFocus()
                    } label: {
                        Label(session.isPaused ? "继续" : "暂停", systemImage: session.isPaused ? "play.fill" : "pause.fill")
                    }

                    Spacer()
                }

                TextField("结束前记录实际做了什么", text: $viewModel.finishActivityDraft)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .finishActivity)
                    .onSubmit {
                        if viewModel.finishFocus() {
                            focusedField = .quickNote
                        } else {
                            focusedField = .finishActivity
                        }
                    }

                Button {
                    _ = viewModel.finishFocus()
                } label: {
                    Label("结束并保存", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("专注")
                    .font(.subheadline.weight(.semibold))
                TextField("计划做什么，可不填", text: $viewModel.plannedActivityDraft)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .plannedActivity)
                    .onSubmit {
                        if viewModel.startFocus() {
                            focusedField = .finishActivity
                        }
                    }
                Button {
                    _ = viewModel.startFocus()
                } label: {
                    Label("开始专注", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var quickNoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速记录")
                .font(.subheadline.weight(.semibold))
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.quickNoteDraft)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 5)
                    .focused($focusedField, equals: .quickNote)

                if viewModel.quickNoteDraft.isEmpty {
                    Text("灵感、碎碎念、临时备注")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 88)
            .background(.quaternary.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.quaternary)
            }
            Button {
                _ = viewModel.addQuickNote()
                focusedField = .quickNote
            } label: {
                Label("记录一条", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日时间线")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if viewModel.todayEntriesNewestFirst.isEmpty == false {
                    Text("\(viewModel.todayEntriesNewestFirst.count) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.todayEntriesNewestFirst.isEmpty {
                Text("今天还没有记录。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.todayEntriesNewestFirst) { entry in
                            TimelineRow(
                                entry: entry,
                                now: viewModel.now,
                                onSave: { viewModel.updateEntryText(entry, to: $0) },
                                onDelete: { viewModel.deleteEntry(entry) }
                            )
                        }
                    }
                }
                .frame(minHeight: 130, maxHeight: 260)
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    viewModel.chooseExportDirectory()
                } label: {
                    Label("选择导出目录", systemImage: "folder")
                }

                Text(viewModel.exportDirectoryDisplay)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .keyboardShortcut("q", modifiers: .command)
            .help("退出一日一笺")
            .accessibilityLabel("退出一日一笺")
        }
    }
}

private enum FocusedField: Hashable {
    case plannedActivity
    case finishActivity
    case quickNote
}

private struct TimelineRow: View {
    let entry: DayEntry
    let now: Date
    let onSave: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var draft = ""
    @State private var confirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Label(typeTitle, systemImage: iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(typeColor)
                Spacer()
                Text(timeSummary)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if canEdit {
                    actionMenu
                }
            }

            if isEditing {
                editor
            } else {
                Text(content)
                    .font(.callout)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            if confirmingDelete {
                deleteConfirm
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("修改内容", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit { commitEdit() }
            HStack {
                Spacer()
                Button("取消") { isEditing = false }
                    .buttonStyle(.bordered)
                Button("保存") { commitEdit() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var deleteConfirm: some View {
        HStack(spacing: 8) {
            Text("确认删除这条记录？")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("取消") { confirmingDelete = false }
                .buttonStyle(.bordered)
            Button(role: .destructive) {
                confirmingDelete = false
                onDelete()
            } label: {
                Text("删除")
            }
            .buttonStyle(.borderedProminent)
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

    private var iconName: String {
        switch entry {
        case .focusSession(let session):
            session.endedAt == nil ? "timer" : "checkmark.circle"
        case .quickNote:
            "text.bubble"
        }
    }

    private var typeColor: Color {
        switch entry {
        case .focusSession:
            .accentColor
        case .quickNote:
            .primary
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
