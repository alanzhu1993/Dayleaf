# Global Quick Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a configurable global shortcut that opens a quick-capture-only window, focuses the input, saves a quick note with `Return`, and closes immediately after a successful save.

**Architecture:** Keep shortcut configuration in `DayleafCore` settings, register the configured shortcut in the app target with native Carbon hotkey APIs, and use a small AppKit-managed `NSWindow` for quick capture. Reuse the existing `QuickNoteEditor` input behavior and route all saves through one `DayleafViewModel.addQuickNote(content:)` method.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Carbon `RegisterEventHotKey`, existing `DayleafCore`, existing `DayleafCoreCheck`.

---

## File Structure

- Modify `Sources/DayleafCore/Settings.swift`
  - Add `KeyboardShortcutSpec`.
  - Add `quickCaptureShortcut` to `DayleafSettings`.
  - Add the default `Control + Option + Space` shortcut.
- Modify `Sources/DayleafCoreCheck/main.swift`
  - Add checks for shortcut defaulting and settings JSON round trip.
- Modify `Sources/DayleafApp/DayleafViewModel.swift`
  - Add `addQuickNote(content:)`.
  - Keep existing menu-bar quick-note behavior by delegating to the new method.
  - Add settings helpers for shortcut display and saving.
- Modify `Sources/DayleafApp/QuickNoteEditor.swift`
  - Add programmatic focus support.
  - Add `Escape` cancel support.
- Create `Sources/DayleafApp/QuickCaptureWindowView.swift`
  - Small SwiftUI surface with only quick note input and status text.
- Create `Sources/DayleafApp/QuickCaptureWindowPresenter.swift`
  - AppKit presenter for the floating quick capture window.
- Create `Sources/DayleafApp/GlobalShortcutManager.swift`
  - Native global shortcut registration and dispatch.
- Create `Sources/DayleafApp/ShortcutRecorder.swift`
  - Local settings control for recording a new shortcut.
- Create `Sources/DayleafApp/DayleafAppCoordinator.swift`
  - Owns the view model, shortcut manager, and quick-capture presenter.
- Modify `Sources/DayleafApp/DayleafApplication.swift`
  - Use the coordinator and register the shortcut at app startup.
- Modify `Sources/DayleafApp/MenuBarRootView.swift`
  - Add shortcut settings to the compact settings popover.
- Modify `Sources/DayleafApp/SettingsView.swift`
  - Replace the placeholder shortcut copy with the real recorder.

---

### Task 1: Core Shortcut Model

**Files:**
- Modify: `Sources/DayleafCore/Settings.swift`
- Modify: `Sources/DayleafCoreCheck/main.swift`

- [ ] **Step 1: Add the shortcut model to settings**

Edit `Sources/DayleafCore/Settings.swift` so it contains this shortcut model above `DayleafSettings`, and add `quickCaptureShortcut` to `DayleafSettings`:

```swift
import Foundation

public struct KeyboardShortcutSpec: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Equatable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let command = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let control = Modifiers(rawValue: 1 << 2)
        public static let shift = Modifiers(rawValue: 1 << 3)
    }

    public var keyCode: UInt16
    public var keyEquivalent: String
    public var modifiers: Modifiers

    public init(keyCode: UInt16, keyEquivalent: String, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
    }

    public static let defaultQuickCapture = KeyboardShortcutSpec(
        keyCode: 49,
        keyEquivalent: "Space",
        modifiers: [.control, .option]
    )

    public var displayText: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyEquivalent)
        return parts.joined()
    }

    public var hasRequiredModifier: Bool {
        modifiers.intersection([.command, .option, .control]).isEmpty == false
    }
}

public struct DayleafSettings: Codable, Equatable, Sendable {
    public var exportDirectoryPath: String?
    public var aiBaseURL: String?
    public var aiModel: String?
    public var quickCaptureShortcut: KeyboardShortcutSpec?

    public init(
        exportDirectoryPath: String? = nil,
        aiBaseURL: String? = nil,
        aiModel: String? = nil,
        quickCaptureShortcut: KeyboardShortcutSpec? = nil
    ) {
        self.exportDirectoryPath = exportDirectoryPath?.nilIfBlank
        self.aiBaseURL = aiBaseURL?.nilIfBlank
        self.aiModel = aiModel?.nilIfBlank
        self.quickCaptureShortcut = quickCaptureShortcut
    }

    public var resolvedQuickCaptureShortcut: KeyboardShortcutSpec {
        quickCaptureShortcut ?? .defaultQuickCapture
    }

    public func resolvedExportDirectoryURL(fileManager: FileManager = .default) -> URL {
        if let exportDirectoryPath {
            return URL(fileURLWithPath: exportDirectoryPath, isDirectory: true)
        }
        return Self.defaultExportDirectoryURL(fileManager: fileManager)
    }

    public static func defaultExportDirectoryURL(fileManager: FileManager = .default) -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Documents", isDirectory: true)
        return documentsURL.appendingPathComponent("一日一笺", isDirectory: true)
    }
}
```

- [ ] **Step 2: Add core checks**

In `Sources/DayleafCoreCheck/main.swift`, call the new check after `checkJSONStoreRoundTrip()`:

```swift
try checkShortcutSettingsRoundTrip()
```

Add this method before `expect(...)`:

```swift
private static func checkShortcutSettingsRoundTrip() throws {
    let defaultSettings = DayleafSettings()
    try expect(
        defaultSettings.resolvedQuickCaptureShortcut == .defaultQuickCapture,
        "missing shortcut setting should use default quick capture shortcut"
    )
    try expect(
        defaultSettings.resolvedQuickCaptureShortcut.displayText == "⌃⌥Space",
        "default shortcut display should be control-option-space"
    )

    let customShortcut = KeyboardShortcutSpec(
        keyCode: 45,
        keyEquivalent: "N",
        modifiers: [.command, .option]
    )
    let customSettings = DayleafSettings(quickCaptureShortcut: customShortcut)
    let data = try JSONEncoder().encode(customSettings)
    let decoded = try JSONDecoder().decode(DayleafSettings.self, from: data)

    try expect(
        decoded.resolvedQuickCaptureShortcut == customShortcut,
        "custom shortcut should round trip through settings JSON"
    )
    try expect(
        customShortcut.hasRequiredModifier,
        "shortcut with command or option or control should be valid"
    )
    try expect(
        KeyboardShortcutSpec(keyCode: 0, keyEquivalent: "A", modifiers: [.shift]).hasRequiredModifier == false,
        "plain shift shortcut should not be accepted"
    )
}
```

- [ ] **Step 3: Run core check**

Run:

```bash
swift run DayleafCoreCheck
```

Expected:

```text
DayleafCoreCheck passed
```

- [ ] **Step 4: Commit**

```bash
git add Sources/DayleafCore/Settings.swift Sources/DayleafCoreCheck/main.swift
git commit -m "feat: add quick capture shortcut setting"
```

---

### Task 2: Shared Quick Note Save Path

**Files:**
- Modify: `Sources/DayleafApp/DayleafViewModel.swift`

- [ ] **Step 1: Add view-model shortcut state and shared save method**

In `DayleafViewModel`, add this published state near the other `@Published` properties:

```swift
@Published private(set) var quickCaptureShortcutRegistrationMessage: String?
```

Add these computed properties near `exportDirectoryDisplay`:

```swift
var quickCaptureShortcut: KeyboardShortcutSpec {
    settings.resolvedQuickCaptureShortcut
}

var quickCaptureShortcutDisplay: String {
    quickCaptureShortcut.displayText
}
```

Replace the existing `addQuickNote()` with this pair:

```swift
@discardableResult
func addQuickNote() -> Bool {
    let saved = addQuickNote(content: quickNoteDraft)
    if saved {
        quickNoteDraft = ""
    }
    return saved
}

@discardableResult
func addQuickNote(content rawContent: String) -> Bool {
    let content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
    guard content.isEmpty == false else {
        statusMessage = "先写一点内容。"
        return false
    }

    let occurredAt = Date()
    mutateDatabase { database in
        database.quickNotes.append(QuickNote(content: content, occurredAt: occurredAt))
    }
    statusMessage = "碎碎念已记录。"
    return true
}
```

Add these methods near `saveAISettings()`:

```swift
func saveQuickCaptureShortcut(_ shortcut: KeyboardShortcutSpec) {
    guard shortcut.hasRequiredModifier else {
        statusMessage = "快捷键需要包含 Command、Option 或 Control。"
        return
    }
    settings.quickCaptureShortcut = shortcut
    saveSettings()
    statusMessage = "快速记录快捷键已更新。"
}

func setQuickCaptureShortcutRegistrationMessage(_ message: String?) {
    quickCaptureShortcutRegistrationMessage = message
}
```

- [ ] **Step 2: Run build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/DayleafApp/DayleafViewModel.swift
git commit -m "feat: share quick note save logic"
```

---

### Task 3: Make `QuickNoteEditor` Focusable and Cancellable

**Files:**
- Modify: `Sources/DayleafApp/QuickNoteEditor.swift`

- [ ] **Step 1: Extend the editor API**

In `QuickNoteEditor`, add `focusTrigger` and `onCancel`:

```swift
struct QuickNoteEditor: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var focusTrigger: Int = 0
    var onSubmit: () -> Void
    var onCancel: () -> Void = {}
    var onFocusChange: (Bool) -> Void = { _ in }
```

- [ ] **Step 2: Programmatically focus the text view**

In `updateNSView`, after the string sync block, add:

```swift
if context.coordinator.lastFocusTrigger != focusTrigger {
    context.coordinator.lastFocusTrigger = focusTrigger
    DispatchQueue.main.async {
        scrollView.window?.makeFirstResponder(textView)
    }
}
```

Add this property to `Coordinator`:

```swift
var lastFocusTrigger = 0
```

- [ ] **Step 3: Add Escape handling**

In `textView(_:doCommandBy:)`, add this branch before `return false`:

```swift
if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
    parent.onCancel()
    return true
}
```

- [ ] **Step 4: Run build**

Run:

```bash
swift build
```

Expected: build succeeds and existing `QuickNoteEditor(...)` call sites compile because the new parameters have defaults.

- [ ] **Step 5: Commit**

```bash
git add Sources/DayleafApp/QuickNoteEditor.swift
git commit -m "feat: support quick note editor focus"
```

---

### Task 4: Quick Capture Floating Window

**Files:**
- Create: `Sources/DayleafApp/QuickCaptureWindowView.swift`
- Create: `Sources/DayleafApp/QuickCaptureWindowPresenter.swift`

- [ ] **Step 1: Create the quick capture view**

Create `Sources/DayleafApp/QuickCaptureWindowView.swift`:

```swift
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
```

- [ ] **Step 2: Create the presenter**

Create `Sources/DayleafApp/QuickCaptureWindowPresenter.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class QuickCaptureWindowPresenter {
    private var window: NSWindow?

    func show(viewModel: DayleafViewModel) {
        let window = existingOrNewWindow(viewModel: viewModel)
        position(window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
        window = nil
    }

    private func existingOrNewWindow(viewModel: DayleafViewModel) -> NSWindow {
        if let window {
            return window
        }

        let rootView = QuickCaptureWindowView(
            viewModel: viewModel,
            onSave: { [weak self] in
                self?.close()
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )

        let hostingView = NSHostingView(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 148),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "快速记录"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = hostingView
        window.center()
        self.window = window
        return window
    }

    private func position(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main

        guard let screen else {
            window.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let size = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2
        )
        window.setFrameOrigin(origin)
    }
}
```

- [ ] **Step 3: Run build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Sources/DayleafApp/QuickCaptureWindowView.swift Sources/DayleafApp/QuickCaptureWindowPresenter.swift
git commit -m "feat: add quick capture window"
```

---

### Task 5: Global Shortcut Registration

**Files:**
- Create: `Sources/DayleafApp/GlobalShortcutManager.swift`
- Create: `Sources/DayleafApp/DayleafAppCoordinator.swift`
- Modify: `Sources/DayleafApp/DayleafApplication.swift`

- [ ] **Step 1: Add the global shortcut manager**

Create `Sources/DayleafApp/GlobalShortcutManager.swift`:

```swift
import Carbon
import Combine
import DayleafCore
import Foundation

@MainActor
final class GlobalShortcutManager: ObservableObject {
    @Published private(set) var registrationMessage: String?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onTrigger: (() -> Void)?
    private let signature = OSType(UInt32(UInt8(ascii: "D")) << 24 | UInt32(UInt8(ascii: "L")) << 16 | UInt32(UInt8(ascii: "Q")) << 8 | UInt32(UInt8(ascii: "C")))
    private let hotKeyID = UInt32(1)

    func register(shortcut: KeyboardShortcutSpec, onTrigger: @escaping () -> Void) {
        unregister()
        self.onTrigger = onTrigger

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.onTrigger?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard handlerStatus == noErr else {
            registrationMessage = "快速记录快捷键注册失败（\(handlerStatus)）。"
            return
        }

        var id = EventHotKeyID(signature: signature, id: hotKeyID)
        let registerStatus = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            carbonModifiers(for: shortcut.modifiers),
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus == noErr {
            registrationMessage = nil
        } else {
            registrationMessage = "快捷键 \(shortcut.displayText) 可能已被占用。"
            unregister()
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func carbonModifiers(for modifiers: KeyboardShortcutSpec.Modifiers) -> UInt32 {
        var carbon: UInt32 = 0
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }
}
```

- [ ] **Step 2: Add the coordinator**

Create `Sources/DayleafApp/DayleafAppCoordinator.swift`:

```swift
import Combine
import Foundation

@MainActor
final class DayleafAppCoordinator: ObservableObject {
    let viewModel: DayleafViewModel
    let shortcutManager: GlobalShortcutManager
    private let quickCapturePresenter: QuickCaptureWindowPresenter
    private var cancellables: Set<AnyCancellable> = []

    init(
        viewModel: DayleafViewModel = DayleafViewModel(),
        shortcutManager: GlobalShortcutManager = GlobalShortcutManager(),
        quickCapturePresenter: QuickCaptureWindowPresenter = QuickCaptureWindowPresenter()
    ) {
        self.viewModel = viewModel
        self.shortcutManager = shortcutManager
        self.quickCapturePresenter = quickCapturePresenter
        viewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        registerQuickCaptureShortcut()
    }

    func registerQuickCaptureShortcut() {
        shortcutManager.register(shortcut: viewModel.quickCaptureShortcut) { [weak self] in
            guard let self else { return }
            self.quickCapturePresenter.show(viewModel: self.viewModel)
        }
        viewModel.setQuickCaptureShortcutRegistrationMessage(shortcutManager.registrationMessage)
    }
}
```

- [ ] **Step 3: Use coordinator from app entry**

Replace `Sources/DayleafApp/DayleafApplication.swift` with:

```swift
import SwiftUI

@main
struct DayleafApplication: App {
    @StateObject private var coordinator = DayleafAppCoordinator()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(onShortcutChanged: coordinator.registerQuickCaptureShortcut)
                .environmentObject(coordinator.viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: coordinator.viewModel.menuSystemImage)
                if coordinator.viewModel.menuTitle.isEmpty == false {
                    Text(coordinator.viewModel.menuTitle)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(onShortcutChanged: coordinator.registerQuickCaptureShortcut)
                .environmentObject(coordinator.viewModel)
        }
    }
}
```

This intentionally changes `MenuBarRootView` and `SettingsView` initializers. Task 6 will add those parameters.

- [ ] **Step 4: Run build and confirm expected failures**

Run:

```bash
swift build
```

Expected: build fails because `MenuBarRootView(onShortcutChanged:)` and `SettingsView(onShortcutChanged:)` do not exist yet. Continue to Task 6 before committing.

---

### Task 6: Shortcut Recorder in Settings

**Files:**
- Create: `Sources/DayleafApp/ShortcutRecorder.swift`
- Modify: `Sources/DayleafApp/MenuBarRootView.swift`
- Modify: `Sources/DayleafApp/SettingsView.swift`

- [ ] **Step 1: Add shortcut recorder control**

Create `Sources/DayleafApp/ShortcutRecorder.swift`:

```swift
import AppKit
import DayleafCore
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: KeyboardShortcutSpec
    let onChange: (KeyboardShortcutSpec) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.shortcut = shortcut
        button.onChange = onChange
        return button
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.shortcut = shortcut
        nsView.onChange = onChange
    }
}

final class ShortcutRecorderButton: NSButton {
    var shortcut: KeyboardShortcutSpec = .defaultQuickCapture {
        didSet {
            if isRecording == false {
                title = shortcut.displayText
            }
        }
    }
    var onChange: ((KeyboardShortcutSpec) -> Void)?
    private var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        title = "按下新的快捷键"
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        let modifiers = KeyboardShortcutSpec.Modifiers(event.modifierFlags)
        let keyEquivalent = Self.displayName(for: event)
        let shortcut = KeyboardShortcutSpec(
            keyCode: UInt16(event.keyCode),
            keyEquivalent: keyEquivalent,
            modifiers: modifiers
        )

        guard shortcut.hasRequiredModifier else {
            title = "需要 ⌘ / ⌥ / ⌃"
            NSSound.beep()
            return
        }

        isRecording = false
        self.shortcut = shortcut
        onChange?(shortcut)
    }

    override func cancelOperation(_ sender: Any?) {
        isRecording = false
        title = shortcut.displayText
        window?.makeFirstResponder(nil)
    }

    private static func displayName(for event: NSEvent) -> String {
        if event.keyCode == 49 {
            return "Space"
        }
        if event.keyCode == 36 {
            return "Return"
        }
        if event.keyCode == 53 {
            return "Escape"
        }
        return event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
    }
}

private extension KeyboardShortcutSpec.Modifiers {
    init(_ flags: NSEvent.ModifierFlags) {
        var modifiers: KeyboardShortcutSpec.Modifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        self = modifiers
    }
}
```

- [ ] **Step 2: Add settings callback to compact menu settings**

Change the `MenuBarRootView` declaration:

```swift
struct MenuBarRootView: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    let onShortcutChanged: () -> Void
```

Update the settings popover call:

```swift
SettingsPanel(onStatusMessage: presentToast, onShortcutChanged: onShortcutChanged)
    .environmentObject(viewModel)
```

Change `SettingsPanel` to accept the callback:

```swift
private struct SettingsPanel: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    @AppStorage(AppThemeStore.key) private var themeRaw = AppThemeStore.default
    let onStatusMessage: (String?) -> Void
    let onShortcutChanged: () -> Void
```

Insert this shortcut section after the theme section:

```swift
VStack(alignment: .leading, spacing: 7) {
    Text("快捷键")
        .font(.caption.weight(.semibold))
        .foregroundStyle(Palette.textSecondary)

    ShortcutRecorder(shortcut: viewModel.quickCaptureShortcut) { shortcut in
        viewModel.saveQuickCaptureShortcut(shortcut)
        onShortcutChanged()
        onStatusMessage(viewModel.statusMessage)
    }
    .frame(height: 30)

    if let message = viewModel.quickCaptureShortcutRegistrationMessage {
        Text(message)
            .font(.caption2)
            .foregroundStyle(Palette.danger)
            .fixedSize(horizontal: false, vertical: true)
    } else {
        Text("用于弹出快速记录浮窗。")
            .font(.caption2)
            .foregroundStyle(Palette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
```

- [ ] **Step 3: Replace the system Settings shortcut placeholder**

Change `SettingsView` declaration:

```swift
struct SettingsView: View {
    @EnvironmentObject private var viewModel: DayleafViewModel
    let onShortcutChanged: () -> Void
```

Replace the current `Section("快捷键")` with:

```swift
Section {
    LabeledContent("快速记录快捷键") {
        ShortcutRecorder(shortcut: viewModel.quickCaptureShortcut) { shortcut in
            viewModel.saveQuickCaptureShortcut(shortcut)
            onShortcutChanged()
        }
        .frame(width: 180, height: 30)
    }

    if let message = viewModel.quickCaptureShortcutRegistrationMessage {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
    }
} header: {
    Text("快捷键")
} footer: {
    Text("按下快捷键后，会弹出只用于快速记录的小窗口。")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

- [ ] **Step 4: Run build and core check**

Run:

```bash
swift build
swift run DayleafCoreCheck
```

Expected:

```text
DayleafCoreCheck passed
```

- [ ] **Step 5: Commit Task 5 and Task 6 together**

Task 5 intentionally introduced temporary compile failures. Commit the global shortcut and settings UI after this task passes:

```bash
git add Sources/DayleafApp/GlobalShortcutManager.swift Sources/DayleafApp/DayleafAppCoordinator.swift Sources/DayleafApp/DayleafApplication.swift Sources/DayleafApp/ShortcutRecorder.swift Sources/DayleafApp/MenuBarRootView.swift Sources/DayleafApp/SettingsView.swift
git commit -m "feat: register configurable quick capture shortcut"
```

---

### Task 7: Runtime Verification and Polish

**Files:**
- Inspect: `Sources/DayleafApp`
- Modify only if manual verification exposes an issue.

- [ ] **Step 1: Run baseline checks**

Run:

```bash
swift build
swift run DayleafCoreCheck
```

Expected:

```text
DayleafCoreCheck passed
```

- [ ] **Step 2: Launch the app**

Run:

```bash
swift run Dayleaf
```

Expected: app launches and appears in the macOS menu bar.

- [ ] **Step 3: Verify default shortcut**

Manual check:

- Press `Control + Option + Space`.
- Expected: quick capture floating window appears.
- Expected: text cursor is already inside the input field.

- [ ] **Step 4: Verify save and close**

Manual check:

- Type `测试全局快速记录`.
- Press `Return`.
- Expected: quick capture window closes immediately.
- Open the menu bar popover.
- Expected: today's timeline includes `测试全局快速记录`.

- [ ] **Step 5: Verify multiline and cancel**

Manual check:

- Press `Control + Option + Space`.
- Type `第一行`.
- Press `Shift + Return`.
- Type `第二行`.
- Expected: second line appears in the same editor.
- Press `Escape`.
- Expected: window closes and the draft is not saved.

- [ ] **Step 6: Verify empty input behavior**

Manual check:

- Press `Control + Option + Space`.
- Press `Return` without typing.
- Expected: window remains open and shows `先写一点内容。`.
- Press `Escape`.
- Expected: window closes.

- [ ] **Step 7: Verify shortcut recording**

Manual check:

- Open settings.
- Click `快速记录快捷键`.
- Press `Control + Option + N`.
- Expected: displayed shortcut changes to `⌃⌥N`.
- Press old shortcut `Control + Option + Space`.
- Expected: old shortcut no longer opens quick capture.
- Press new shortcut `Control + Option + N`.
- Expected: quick capture opens.

- [ ] **Step 8: Verify existing menu-bar quick note still works**

Manual check:

- Open the menu bar popover.
- Type `菜单栏快速记录仍可用`.
- Press `Return`.
- Expected: note is saved and appears in the timeline.

- [ ] **Step 9: Commit any polish fixes**

If no fixes were needed, do not create an empty commit. If fixes were needed:

```bash
git add Sources/DayleafApp
git commit -m "fix: polish quick capture runtime behavior"
```

---

## Self-Review Notes

- Spec coverage: the plan covers the quick-capture-only window, immediate focus, `Return` save and close, `Shift + Return`, `Escape`, customizable shortcut, conflict messaging, local JSON persistence, and no monitoring/cloud/AI behavior.
- Placeholder scan: no unfinished placeholder steps are intentionally left in this plan.
- Type consistency: `KeyboardShortcutSpec`, `DayleafSettings.quickCaptureShortcut`, `DayleafViewModel.addQuickNote(content:)`, `GlobalShortcutManager`, `QuickCaptureWindowPresenter`, and `ShortcutRecorder` are introduced before later tasks reference them.
