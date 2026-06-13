import Foundation

public final class JSONDayLogStore {
    private let directoryURL: URL
    private let databaseURL: URL
    private let settingsURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.directoryURL = directoryURL
        self.databaseURL = directoryURL.appendingPathComponent("day-log.json")
        self.settingsURL = directoryURL.appendingPathComponent("settings.json")
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public static func live(fileManager: FileManager = .default) -> JSONDayLogStore {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return JSONDayLogStore(
            directoryURL: appSupportURL.appendingPathComponent("DayLog", isDirectory: true),
            fileManager: fileManager
        )
    }

    public func loadDatabase() throws -> DayLogDatabase {
        guard fileManager.fileExists(atPath: databaseURL.path) else {
            return DayLogDatabase()
        }
        let data = try Data(contentsOf: databaseURL)
        return try decoder.decode(DayLogDatabase.self, from: data)
    }

    public func saveDatabase(_ database: DayLogDatabase) throws {
        try ensureDirectoryExists()
        let data = try encoder.encode(database)
        try data.write(to: databaseURL, options: [.atomic])
    }

    public func loadSettings() throws -> DayLogSettings {
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            return DayLogSettings()
        }
        let data = try Data(contentsOf: settingsURL)
        return try decoder.decode(DayLogSettings.self, from: data)
    }

    public func saveSettings(_ settings: DayLogSettings) throws {
        try ensureDirectoryExists()
        let data = try encoder.encode(settings)
        try data.write(to: settingsURL, options: [.atomic])
    }

    private func ensureDirectoryExists() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
