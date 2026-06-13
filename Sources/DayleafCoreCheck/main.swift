import DayleafCore
import Foundation

@main
struct DayleafCoreCheck {
    static func main() throws {
        try checkFocusDurationExcludesPausedIntervals()
        try checkEntriesAreFilteredAndSorted()
        try checkMarkdownExportUsesConfiguredDirectory()
        try checkJSONStoreRoundTrip()
        print("DayleafCoreCheck passed")
    }

    private static func checkFocusDurationExcludesPausedIntervals() throws {
        let startedAt = date("2026-06-13T09:00:00Z")
        let endedAt = date("2026-06-13T09:40:00Z")
        let session = FocusSession(
            plannedActivity: "Write proposal",
            actualActivity: "Drafted proposal",
            startedAt: startedAt,
            endedAt: endedAt,
            pauseIntervals: [
                PauseInterval(
                    startedAt: date("2026-06-13T09:10:00Z"),
                    endedAt: date("2026-06-13T09:20:00Z")
                )
            ]
        )

        try expect(session.activeDuration(until: endedAt) == 1_800, "paused intervals should be excluded")
        try expect(MarkdownExporter.durationText(session.activeDuration(until: endedAt)) == "30分钟", "duration should be human-readable in Chinese")
    }

    private static func checkEntriesAreFilteredAndSorted() throws {
        let targetDay = date("2026-06-13T12:00:00Z")
        let database = DayleafDatabase(
            focusSessions: [
                FocusSession(
                    actualActivity: "Focus later",
                    startedAt: date("2026-06-13T10:00:00Z"),
                    endedAt: date("2026-06-13T10:30:00Z"),
                    activeDurationSeconds: 1_800
                ),
                FocusSession(
                    actualActivity: "Other day",
                    startedAt: date("2026-06-14T10:00:00Z"),
                    endedAt: date("2026-06-14T10:30:00Z"),
                    activeDurationSeconds: 1_800
                )
            ],
            quickNotes: [
                QuickNote(content: "Earlier note", occurredAt: date("2026-06-13T09:30:00Z")),
                QuickNote(content: "Other day note", occurredAt: date("2026-06-14T09:30:00Z"))
            ]
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let entries = database.entries(on: targetDay, calendar: calendar)

        try expect(entries.count == 2, "entries should be filtered to target day")
        try expect(entries.map(\.typeLabel) == ["Note", "Focus"], "entries should be sorted by occurrence time")
    }

    private static func checkMarkdownExportUsesConfiguredDirectory() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let exportedAt = date("2026-06-13T12:00:00Z")
        let database = DayleafDatabase(
            focusSessions: [
                FocusSession(
                    plannedActivity: "Write proposal",
                    actualActivity: "写客户方案",
                    startedAt: date("2026-06-13T09:10:00Z"),
                    endedAt: date("2026-06-13T09:52:00Z"),
                    activeDurationSeconds: 2_520
                )
            ],
            quickNotes: [
                QuickNote(content: "想到一个销售复盘角度", occurredAt: date("2026-06-13T10:03:12Z"))
            ]
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let exporter = MarkdownExporter(calendar: calendar, timeZone: TimeZone(secondsFromGMT: 0)!)

        let result = try exporter.export(
            date: exportedAt,
            database: database,
            settings: DayleafSettings(exportDirectoryPath: temporaryDirectory.path),
            exportedAt: exportedAt
        )

        try expect(FileManager.default.fileExists(atPath: result.fileURL.path), "export file should exist")
        try expect(result.fileURL.deletingLastPathComponent().path == temporaryDirectory.path, "export should use configured directory")
        try expect(result.fileURL.lastPathComponent == "2026-06-13-一日一笺.md", "export file should use Chinese product name")
        try expect(result.markdown.contains("# 2026-06-13 一日一笺"), "markdown should include Chinese title")
        try expect(result.markdown.contains("## 概览"), "markdown should include Chinese summary section")
        try expect(result.markdown.contains("| 时间 | 时间戳 | 类型 | 内容 | 时长 |"), "markdown should include Chinese timeline table")
        try expect(result.markdown.contains("| 09:10 | 2026-06-13T09:10:00Z | 专注 | 写客户方案 | 42分钟 |"), "markdown should include Chinese focus row")
        try expect(result.markdown.contains("| 10:03 | 2026-06-13T10:03:12Z | 记录 | 想到一个销售复盘角度 | - |"), "markdown should include Chinese note row")
        try expect(result.markdown.contains("2026-06-13T10:03:12Z"), "markdown should include precise timestamp")
        try expect(result.markdown.contains("## 给人工智能的提示"), "markdown should include Chinese AI prompt section")
        try expect(result.markdown.contains("像一位真诚、温和的朋友一样"), "markdown should include warm friend-style analysis prompt")
    }

    private static func checkJSONStoreRoundTrip() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        let store = JSONDayleafStore(directoryURL: temporaryDirectory)
        let database = DayleafDatabase(
            focusSessions: [
                FocusSession(
                    actualActivity: "Completed focus",
                    startedAt: date("2026-06-13T09:00:00Z"),
                    endedAt: date("2026-06-13T09:30:00Z"),
                    activeDurationSeconds: 1_800
                )
            ],
            quickNotes: [
                QuickNote(content: "Quick thought", occurredAt: date("2026-06-13T10:00:00Z"))
            ]
        )
        let settings = DayleafSettings(exportDirectoryPath: temporaryDirectory.path)

        try store.saveDatabase(database)
        try store.saveSettings(settings)

        let loadedDatabase = try store.loadDatabase()
        let loadedSettings = try store.loadSettings()

        try expect(loadedDatabase == database, "database should round trip")
        try expect(loadedSettings == settings, "settings should round trip")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if condition() == false {
            throw CheckFailure(message: message)
        }
    }

    private static func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}

private struct CheckFailure: Error, CustomStringConvertible {
    var message: String
    var description: String { message }
}
