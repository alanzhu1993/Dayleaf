import Foundation

public struct DayleafSettings: Codable, Equatable, Sendable {
    public var exportDirectoryPath: String?

    public init(exportDirectoryPath: String? = nil) {
        self.exportDirectoryPath = exportDirectoryPath?.nilIfBlank
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
