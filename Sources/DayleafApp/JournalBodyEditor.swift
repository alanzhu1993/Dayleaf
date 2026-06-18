import AppKit
import SwiftUI

/// 日记正文长文编辑器。SwiftUI TextEditor 在菜单栏 App 打开的独立窗口里偶尔无法稳定获得焦点；
/// 这里直接使用 NSTextView，明确开启可编辑、可选择和撤销。
struct JournalBodyEditor: NSViewRepresentable {
    @Binding var text: String
    var journalID: UUID?
    var onFocusChange: (Bool) -> Void = { _ in }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = JournalTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.frame = NSRect(x: 0, y: 0, width: 560, height: 320)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: textView.frame.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        scrollView.postsFrameChangedNotifications = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.isEditable = true
        textView.isSelectable = true
        let journalChanged = context.coordinator.lastJournalID != journalID
        context.coordinator.lastJournalID = journalID
        if textView.hasMarkedText(), journalChanged == false { return }
        if textView.window?.firstResponder === textView, journalChanged == false { return }
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            let location = journalChanged ? 0 : min(selectedRange.location, textView.string.count)
            textView.setSelectedRange(NSRange(location: location, length: 0))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: JournalBodyEditor
        var lastJournalID: UUID?

        init(_ parent: JournalBodyEditor) {
            self.parent = parent
            self.lastJournalID = parent.journalID
        }

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
    }
}

private final class JournalTextView: NSTextView {
    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(self)
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(self)

        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) {
            super.keyDown(with: event)
            return
        }

        switch event.charactersIgnoringModifiers {
        case "\u{7F}":
            deleteBackward(nil)
        case "\u{08}":
            deleteBackward(nil)
        case "\r":
            insertNewline(nil)
        case "\t":
            insertTab(nil)
        default:
            if let characters = event.characters, characters.isEmpty == false {
                insertText(characters, replacementRange: selectedRange())
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
