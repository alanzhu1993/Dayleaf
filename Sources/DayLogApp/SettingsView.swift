import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: DayLogViewModel

    var body: some View {
        Form {
            Section("导出") {
                Text("当前目录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.exportDirectoryDisplay)
                    .textSelection(.enabled)

                Button {
                    viewModel.chooseExportDirectory()
                } label: {
                    Label("选择导出目录", systemImage: "folder")
                }
            }

            Section("快捷键") {
                Text("Swift Package 原型暂不注册全局快捷键。正式 .app 打包阶段再加入可配置快捷键。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
