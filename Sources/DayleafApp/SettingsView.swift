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
                    Label("选择导出目录", systemImage: "folder")
                }
            } header: {
                Text("导出")
            } footer: {
                Text("每天的记录会导出为标记文本，保存到此目录。")
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
}
