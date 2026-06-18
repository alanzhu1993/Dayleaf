import AppKit
import SwiftUI

/// 快速记录输入框。基于 NSTextView，行为完全可控：
/// - 回车：保存（调用 onSubmit），不换行；
/// - Shift+回车：在光标处插入换行；
/// - 占位文字与正文/光标精确对齐（清零 lineFragmentPadding，占位用同一 inset 绘制）。
struct QuickNoteEditor: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var focusTrigger: Int = 0
    var onSubmit: () -> Void
    var onCancel: () -> Void = {}
    var onFocusChange: (Bool) -> Void = { _ in }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.placeholderString = placeholder
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.textContainerInset = NSSize(width: 5, height: 7)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? PlaceholderTextView else { return }
        textView.placeholderString = placeholder
        func applyFocusIfNeeded() {
            if context.coordinator.lastFocusTrigger != focusTrigger {
                context.coordinator.lastFocusTrigger = focusTrigger
                DispatchQueue.main.async {
                    scrollView.window?.makeFirstResponder(textView)
                }
            }
        }
        // 正在用输入法组字（拼音预编辑）时，绝不回写 string，
        // 否则每秒定时器触发的重绘会抹掉未上屏的内容，打断/取消输入。
        if textView.hasMarkedText() {
            applyFocusIfNeeded()
            return
        }
        if textView.string != text {
            textView.string = text
            textView.needsDisplay = true
        }
        applyFocusIfNeeded()
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: QuickNoteEditor
        var lastFocusTrigger = 0

        init(_ parent: QuickNoteEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.onFocusChange(true)
        }

        func textDidEndEditing(_ notification: Notification) {
            parent.onFocusChange(false)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let shiftHeld = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
                if shiftHeld {
                    return false   // Shift+回车：交给系统在光标处插入换行
                }
                parent.onSubmit()  // 回车：保存
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }
            return false
        }
    }
}

/// 空内容时绘制占位文字的 NSTextView。
final class PlaceholderTextView: NSTextView {
    var placeholderString: String = "" {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty, placeholderString.isEmpty == false else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: font ?? NSFont.preferredFont(forTextStyle: .body)
        ]
        let point = NSPoint(
            x: textContainerInset.width + (textContainer?.lineFragmentPadding ?? 0),
            y: textContainerInset.height
        )
        placeholderString.draw(at: point, withAttributes: attributes)
    }
}
