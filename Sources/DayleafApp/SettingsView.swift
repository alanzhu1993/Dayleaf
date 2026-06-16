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
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 320)
    }

    private static func isErrorStatus(_ message: String) -> Bool {
        ["失败", "不能", "需要", "先写", "已有", "无法"].contains { message.contains($0) }
    }
}
