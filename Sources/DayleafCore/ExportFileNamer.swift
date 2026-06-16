import Foundation

public enum ExportFileNamer {
    public static func availableFileURL(
        in directoryURL: URL,
        baseName: String,
        fileExtension: String,
        fileManager: FileManager = .default
    ) -> URL {
        var candidate = directoryURL.appendingPathComponent("\(baseName).\(fileExtension)")
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent("\(baseName)-\(suffix).\(fileExtension)")
            suffix += 1
        }
        return candidate
    }
}
