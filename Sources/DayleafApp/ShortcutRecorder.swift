import AppKit
import DayleafCore
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: KeyboardShortcutSpec
    let onChange: (KeyboardShortcutSpec) -> Void

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.shortcut = shortcut
        button.onChange = onChange
        button.refreshTitle()
        return button
    }

    func updateNSView(_ nsView: RecorderButton, context: Context) {
        nsView.shortcut = shortcut
        nsView.onChange = onChange
        nsView.refreshTitle()
    }
}

final class RecorderButton: NSButton {
    var shortcut = KeyboardShortcutSpec.defaultQuickCapture
    var onChange: ((KeyboardShortcutSpec) -> Void)?

    private var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    init() {
        super.init(frame: .zero)
        title = shortcut.displayText
        target = self
        action = #selector(startRecording)
        bezelStyle = .rounded
        controlSize = .regular
        setButtonType(.momentaryPushIn)
        focusRingType = .default
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshTitle() {
        if isRecording == false {
            title = shortcut.displayText
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            cancelOperation(nil)
            return
        }

        let modifiers = Self.shortcutModifiers(from: event.modifierFlags)
        guard modifiers.contains(.command) || modifiers.contains(.option) || modifiers.contains(.control) else {
            NSSound.beep()
            title = "需要 ⌘ / ⌥ / ⌃"
            return
        }

        let nextShortcut = KeyboardShortcutSpec(
            keyCode: UInt16(event.keyCode),
            keyEquivalent: Self.displayName(for: event),
            modifiers: modifiers
        )
        shortcut = nextShortcut
        isRecording = false
        refreshTitle()
        window?.makeFirstResponder(nil)
        onChange?(nextShortcut)
    }

    override func cancelOperation(_ sender: Any?) {
        isRecording = false
        refreshTitle()
        window?.makeFirstResponder(nil)
    }

    @objc
    private func startRecording() {
        isRecording = true
        title = "按下新的快捷键"
        window?.makeFirstResponder(self)
    }

    private static func shortcutModifiers(from flags: NSEvent.ModifierFlags) -> KeyboardShortcutSpec.Modifiers {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var modifiers: KeyboardShortcutSpec.Modifiers = []
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        return modifiers
    }

    private static func displayName(for event: NSEvent) -> String {
        switch event.keyCode {
        case 49:
            return "Space"
        case 36:
            return "Return"
        case 53:
            return "Escape"
        default:
            return event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
        }
    }
}
