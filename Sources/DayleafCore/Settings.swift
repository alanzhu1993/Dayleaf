import Foundation

public struct DayleafSettings: Codable, Equatable, Sendable {
    public var exportDirectoryPath: String?
    public var aiBaseURL: String?
    public var aiModel: String?

    public init(
        exportDirectoryPath: String? = nil,
        aiBaseURL: String? = nil,
        aiModel: String? = nil
    ) {
        self.exportDirectoryPath = exportDirectoryPath?.nilIfBlank
        self.aiBaseURL = aiBaseURL?.nilIfBlank
        self.aiModel = aiModel?.nilIfBlank
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
