import Carbon
import Combine
import DayleafCore
import Foundation

@MainActor
final class GlobalShortcutManager: ObservableObject {
    @Published private(set) var registrationMessage: String?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handlerBox: GlobalShortcutHandlerBox?

    func register(shortcut: KeyboardShortcutSpec, onTrigger: @escaping () -> Void) {
        unregister()

        guard shortcut.hasRequiredModifier else {
            registrationMessage = "快捷键需要包含 Command、Option 或 Control。"
            return
        }

        let box = GlobalShortcutHandlerBox(onTrigger: onTrigger)
        handlerBox = box

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        var installedHandler: EventHandlerRef?
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            Self.eventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(box).toOpaque(),
            &installedHandler
        )

        guard installStatus == noErr, let installedHandler else {
            registrationMessage = "无法监听快捷键：\(Self.statusDescription(installStatus))。"
            unregister(clearMessage: false)
            return
        }

        eventHandlerRef = installedHandler

        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: Self.hotKeyID)
        var registeredHotKey: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            Self.carbonModifiers(from: shortcut.modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &registeredHotKey
        )

        guard registerStatus == noErr, let registeredHotKey else {
            registrationMessage = "无法注册快捷键 \(shortcut.displayText)：\(Self.statusDescription(registerStatus))。请换一个组合。"
            unregister(clearMessage: false)
            return
        }

        hotKeyRef = registeredHotKey
        registrationMessage = nil
    }

    func unregister() {
        unregister(clearMessage: true)
    }

    private func unregister(clearMessage: Bool) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }

        hotKeyRef = nil
        eventHandlerRef = nil
        handlerBox = nil
        if clearMessage {
            registrationMessage = nil
        }
    }

    deinit {
        MainActor.assumeIsolated {
            if let hotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
            }
            if let eventHandlerRef {
                RemoveEventHandler(eventHandlerRef)
            }
        }
    }

    private static let hotKeySignature: OSType = 0x444C5143 // DLQC
    private static let hotKeyID: UInt32 = 1

    private static let eventHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else {
            return noErr
        }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr,
              hotKeyID.signature == GlobalShortcutManager.hotKeySignature,
              hotKeyID.id == GlobalShortcutManager.hotKeyID else {
            return noErr
        }

        let address = UInt(bitPattern: userData)
        Task { @MainActor in
            guard let pointer = UnsafeRawPointer(bitPattern: address) else {
                return
            }
            let box = Unmanaged<GlobalShortcutHandlerBox>.fromOpaque(pointer).takeUnretainedValue()
            box.trigger()
        }

        return noErr
    }

    private static func carbonModifiers(from modifiers: KeyboardShortcutSpec.Modifiers) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        return carbonModifiers
    }

    private static func statusDescription(_ status: OSStatus) -> String {
        if status == eventHotKeyExistsErr {
            return "这个快捷键已被占用"
        }
        return "系统返回 \(status)"
    }
}

private final class GlobalShortcutHandlerBox {
    private let onTrigger: () -> Void

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }

    func trigger() {
        onTrigger()
    }
}
