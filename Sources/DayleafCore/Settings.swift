import Foundation

public struct KeyboardShortcutSpec: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Equatable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let command = Self(rawValue: 1 << 0)
        public static let option = Self(rawValue: 1 << 1)
        public static let control = Self(rawValue: 1 << 2)
        public static let shift = Self(rawValue: 1 << 3)
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
        var text = ""
        if modifiers.contains(.control) {
            text += "⌃"
        }
        if modifiers.contains(.option) {
            text += "⌥"
        }
        if modifiers.contains(.shift) {
            text += "⇧"
        }
        if modifiers.contains(.command) {
            text += "⌘"
        }
        return text + keyEquivalent
    }

    public var hasRequiredModifier: Bool {
        modifiers.contains(.command) || modifiers.contains(.option) || modifiers.contains(.control)
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
