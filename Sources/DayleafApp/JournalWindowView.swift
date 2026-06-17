import DayleafCore
import SwiftUI

struct JournalWindowView: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    @AppStorage(AppThemeStore.key) private var themeRaw = AppThemeStore.default

    @State private var titleDraft = ""
    @State private var contentDraft = ""
    @State private var confirmingDelete = false
    @FocusState private var contentEditorFocused: Bool

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }

    var body: some View {
        HStack(spacing: 0) {
            journalList
            Divider()
            editorPane
        }
        .frame(minWidth: 820, idealWidth: 920, minHeight: 560, idealHeight: 640)
        .background(Palette.background)
        .themedWindow(theme.colorScheme)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            syncDrafts()
        }
        .onChange(of: viewModel.selectedJournal?.id) { _, _ in
            syncDrafts()
            confirmingDelete = false
        }
        .onChange(of: viewModel.selectedJournal?.updatedAt) { _, _ in
            syncDrafts()
        }
    }

    private var journalList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("日记")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Button {
                    viewModel.generateJournalForToday()
                } label: {
                    Image(systemName: "sparkles")
                }
                .buttonStyle(IconButtonStyle())
                .help("一笺成文")
                .disabled(viewModel.isGeneratingJournal)
            }

            if viewModel.journalsNewestFirst.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundStyle(Palette.textTertiary)
                    Text("还没有成文的日记")
                        .font(.callout)
                        .foregroundStyle(Palette.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.journalsNewestFirst) { journal in
                            JournalListRow(
                                journal: journal,
                                selected: journal.id == viewModel.selectedJournal?.id
                            ) {
                                viewModel.selectJournal(journal)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(width: 240)
    }

    @ViewBuilder
    private var editorPane: some View {
        if let journal = viewModel.selectedJournal {
            VStack(alignment: .leading, spacing: 14) {
                toolbar(for: journal)
                feedbackPanel

                TextField("标题", text: $titleDraft)
                    .textFieldStyle(.plain)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)

                HStack(spacing: 10) {
                    Text(journal.date.formatted(date: .abbreviated, time: .omitted))
                    Text(journal.editedByUser ? "已编辑" : "AI 成文")
                    Text(journal.modelName)
                    if hasUnsavedChanges(for: journal) {
                        Text("有未保存修改")
                            .foregroundStyle(Palette.warn)
                    }
                }
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)

                Label("正文可直接编辑，改完点保存。", systemImage: "pencil")
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)

                JournalBodyEditor(
                    text: $contentDraft,
                    onFocusChange: { contentEditorFocused = $0 }
                )
                    .padding(4)
                    .frame(minHeight: 260)
                    .softField(focused: contentEditorFocused, elevated: true)

                if confirmingDelete {
                    deleteConfirm(for: journal)
                }
            }
            .padding(22)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(.largeTitle)
                    .foregroundStyle(Palette.textTertiary)
                Text("今天还没有成文的日记")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                Button {
                    viewModel.generateJournalForToday()
                } label: {
                    Label("一笺成文", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle(expand: false))
                .disabled(viewModel.isGeneratingJournal)

                feedbackPanel
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(22)
        }
    }

    private func toolbar(for journal: DailyJournal) -> some View {
        HStack(spacing: 8) {
            Button {
                viewModel.generateJournalForToday()
            } label: {
                Label(viewModel.isGeneratingJournal ? "成文中" : "一笺成文", systemImage: "sparkles")
            }
            .buttonStyle(PrimaryButtonStyle(expand: false))
            .disabled(viewModel.isGeneratingJournal)

            Button {
                _ = viewModel.updateJournal(journal, title: titleDraft, content: contentDraft)
            } label: {
                Label(hasUnsavedChanges(for: journal) ? "保存修改" : "已保存", systemImage: "checkmark")
            }
            .buttonStyle(NeutralButtonStyle(expand: false))
            .disabled(hasUnsavedChanges(for: journal) == false)

            Button {
                viewModel.exportJournalPDF(journal)
            } label: {
                Label("导出 PDF", systemImage: "doc.richtext")
            }
            .buttonStyle(NeutralButtonStyle(expand: false))

            Spacer()

            Button {
                confirmingDelete = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(IconButtonStyle())
            .help("删除日记")
        }
    }

    @ViewBuilder
    private var feedbackPanel: some View {
        if viewModel.isAIConfigured == false {
            JournalAISettingsCard()
                .environmentObject(viewModel)
        } else if let statusMessage = viewModel.statusMessage,
                  statusMessage.contains("一笺成文")
                    || statusMessage.contains("今日一笺")
                    || statusMessage.contains("AI")
                    || statusMessage.contains("可成文")
                    || statusMessage.contains("Base URL")
                    || statusMessage.contains("Model") {
            Label(statusMessage, systemImage: statusMessage.contains("失败") ? "exclamationmark.triangle" : "info.circle")
                .font(.callout)
                .foregroundStyle(statusMessage.contains("失败") ? Palette.warn : Palette.textSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .tile(radius: DS.controlRadius)
        }
    }

    private func deleteConfirm(for journal: DailyJournal) -> some View {
        HStack(spacing: 10) {
            Text("确认删除这篇日记？")
                .font(.callout)
                .foregroundStyle(Palette.textSecondary)
            Spacer()
            Button("取消") {
                confirmingDelete = false
            }
            .buttonStyle(NeutralButtonStyle(expand: false))
            Button("删除") {
                confirmingDelete = false
                viewModel.deleteJournal(journal)
            }
            .buttonStyle(NeutralButtonStyle(fill: Palette.dangerFill, textColor: Palette.danger, expand: false))
        }
        .padding(12)
        .tile(radius: DS.controlRadius)
    }

    private func syncDrafts() {
        titleDraft = viewModel.selectedJournal?.title ?? ""
        contentDraft = viewModel.selectedJournal?.content ?? ""
    }

    private func hasUnsavedChanges(for journal: DailyJournal) -> Bool {
        titleDraft != journal.title || contentDraft != journal.content
    }
}

private struct JournalAISettingsCard: View {
    @EnvironmentObject private var viewModel: DayleafViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(viewModel.aiConfigurationMessage ?? "AI 已配置", systemImage: "key")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            TextField("Base URL", text: $viewModel.aiBaseURLDraft)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .softField(elevated: true)

            TextField("Model", text: $viewModel.aiModelDraft)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .softField(elevated: true)

            HStack(spacing: 8) {
                SecureField(viewModel.hasStoredAPIKey ? "已保存，可输入新 Key 覆盖" : "API Key", text: $viewModel.aiAPIKeyDraft)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .softField(elevated: true)

                Button {
                    viewModel.saveAIAPIKey()
                } label: {
                    Label("保存 Key", systemImage: "key")
                }
                .buttonStyle(NeutralButtonStyle(expand: false))
            }

            HStack(spacing: 8) {
                Button {
                    viewModel.saveAISettings()
                    viewModel.refreshAPIKeyStatus()
                } label: {
                    Label("保存 AI 设置", systemImage: "checkmark")
                }
                .buttonStyle(NeutralButtonStyle(expand: false))

                Text("记录只会在你点击「一笺成文」时发送给配置的 AI 服务。")
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(12)
        .tile(radius: DS.controlRadius)
    }
}

private struct JournalListRow: View {
    let journal: DailyJournal
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(journal.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selected ? .white : Palette.textSecondary)
                Text(journal.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(selected ? .white : Palette.textPrimary)
                    .lineLimit(1)
                Text(journal.content)
                    .font(.caption)
                    .foregroundStyle(selected ? .white.opacity(0.82) : Palette.textTertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .fill(selected ? Palette.accent : Palette.tile)
            }
            .overlay {
                RoundedRectangle(cornerRadius: DS.controlRadius, style: .continuous)
                    .strokeBorder(Palette.tileBorder, lineWidth: DS.hairline)
            }
        }
        .buttonStyle(.plain)
    }
}
