import SwiftUI

struct QuickCaptureWindowView: View {
    @ObservedObject var viewModel: DayleafViewModel
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var draft = ""
    @State private var focusTrigger = 0
    @State private var statusText: String?
    @State private var isInputFocused = false
    @State private var isHovering = false
    @AppStorage(AppThemeStore.key) private var themeRaw = AppThemeStore.default

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("快速记录")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text("Return 保存 · Esc 取消")
                    .font(.caption2)
                    .foregroundStyle(Palette.textTertiary)
            }

            QuickNoteEditor(
                text: $draft,
                placeholder: "马上记下一句",
                focusTrigger: focusTrigger,
                onSubmit: save,
                onCancel: onCancel,
                onFocusChange: { isInputFocused = $0 }
            )
            .frame(height: 72)
            .softField(focused: isInputFocused || isHovering, tint: Palette.note)
            .onHover { isHovering = $0 }

            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusText.contains("失败") || statusText.contains("先写") ? Palette.danger : Palette.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(width: 440)
        .background(Palette.background)
        .themedWindow(theme.colorScheme)
        .onAppear {
            focusTrigger += 1
        }
    }

    private func save() {
        if viewModel.addQuickNote(content: draft) {
            draft = ""
            statusText = nil
            onSave()
        } else {
            statusText = viewModel.statusMessage ?? "保存失败。"
            focusTrigger += 1
        }
    }
}
