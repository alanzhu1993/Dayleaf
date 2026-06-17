import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: DayleafViewModel

    var body: some View {
        Form {
            Section {
                LabeledContent("当前目录") {
                    Text(viewModel.exportDirectoryDisplay)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.trailing)
                }

                Button {
                    viewModel.chooseExportDirectory()
                } label: {
                    Label("选择目录", systemImage: "folder")
                }

                Button {
                    viewModel.saveTodayPDF()
                } label: {
                    Label("保存为 PDF", systemImage: "doc.richtext")
                }

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(Self.isErrorStatus(statusMessage) ? .red : .secondary)
                }
            } header: {
                Text("保存")
            } footer: {
                Text("需要归档时，可以把今天的记录保存成 PDF。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("快捷键") {
                Text("Swift Package 原型暂不注册全局快捷键。正式 .app 打包阶段再加入可配置快捷键。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Base URL", text: $viewModel.aiBaseURLDraft)
                    .textContentType(.URL)
                TextField("Model", text: $viewModel.aiModelDraft)
                Button {
                    viewModel.saveAISettings()
                } label: {
                    Label("保存 AI 设置", systemImage: "checkmark")
                }

                SecureField(viewModel.hasStoredAPIKey ? "已保存，可输入新 Key 覆盖" : "API Key", text: $viewModel.aiAPIKeyDraft)
                Button {
                    viewModel.saveAIAPIKey()
                } label: {
                    Label(viewModel.aiAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "清空 AI Key" : "保存 AI Key", systemImage: "key")
                }

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(Self.isErrorStatus(statusMessage) ? .red : .secondary)
                }
            } header: {
                Text("AI")
            } footer: {
                Text("点击「一笺成文」后，应用会把你确认的今日记录直接发送给你配置的 AI 服务，用来生成第一人称日记。一日一笺没有自有服务器，不收集、不保存、不转发你的记录与日记结果。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 560)
    }

    private static func isErrorStatus(_ message: String) -> Bool {
        ["失败", "不能", "需要", "先写", "已有", "无法"].contains { message.contains($0) }
    }
}
