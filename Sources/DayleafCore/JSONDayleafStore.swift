import Foundation

public final class JSONDayleafStore {
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

    public static func live(fileManager: FileManager = .default) -> JSONDayleafStore {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return JSONDayleafStore(
            directoryURL: appSupportURL.appendingPathComponent("Dayleaf", isDirectory: true),
            fileManager: fileManager
        )
    }

    public func loadDatabase() throws -> DayleafDatabase {
        guard fileManager.fileExists(atPath: databaseURL.path) else {
            return DayleafDatabase()
        }
        let data = try Data(contentsOf: databaseURL)
        return try decoder.decode(DayleafDatabase.self, from: data)
    }

    public func saveDatabase(_ database: DayleafDatabase) throws {
        try ensureDirectoryExists()
        let data = try encoder.encode(database)
        try data.write(to: databaseURL, options: [.atomic])
    }

    public func loadSettings() throws -> DayleafSettings {
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            return DayleafSettings()
        }
        let data = try Data(contentsOf: settingsURL)
        return try decoder.decode(DayleafSettings.self, from: data)
    }

    public func saveSettings(_ settings: DayleafSettings) throws {
        try ensureDirectoryExists()
        let data = try encoder.encode(settings)
        try data.write(to: settingsURL, options: [.atomic])
    }

    private func ensureDirectoryExists() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
