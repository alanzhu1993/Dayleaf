import AppKit
import DayLogCore
import Foundation
import SwiftUI

@MainActor
final class DayLogViewModel: ObservableObject {
    @Published private(set) var database = DayLogDatabase()
    @Published private(set) var settings = DayLogSettings()
    @Published var plannedActivityDraft = ""
    @Published var quickNoteDraft = ""
    @Published var finishActivityDraft = ""
    @Published var statusMessage: String?
    @Published var now = Date()

    private let store: JSONDayLogStore
    private let exporter: MarkdownExporter
    private var timer: Timer?

    init(
        store: JSONDayLogStore = .live(),
        exporter: MarkdownExporter = MarkdownExporter()
    ) {
        self.store = store
        self.exporter = exporter
        load()
        startTicker()
    }

    var menuSystemImage: String {
        if activeSession?.isPaused == true {
            return "pause.circle"
        }
        if activeSession != nil {
            return "timer"
        }
        return "clock"
    }

    var activeSession: FocusSession? {
        guard let index = activeSessionIndex else {
            return nil
        }
        var session = database.focusSessions[index]
        session.refreshActiveDuration(now: now)
        return session
    }

    var todayEntries: [DayEntry] {
        databaseWithRefreshedActiveDuration().entries(on: now)
    }

    var todayEntriesNewestFirst: [DayEntry] {
        todayEntries.sorted { left, right in
            if left.occurredAt == right.occurredAt {
                return left.typeLabel < right.typeLabel
            }
            return left.occurredAt > right.occurredAt
        }
    }

    var exportDirectoryDisplay: String {
        settings.resolvedExportDirectoryURL().path
    }

    @discardableResult
    func startFocus() -> Bool {
        guard activeSessionIndex == nil else {
            statusMessage = "已有专注正在进行。"
            return false
        }

        let startedAt = Date()
        let session = FocusSession(
            plannedActivity: plannedActivityDraft,
            startedAt: startedAt,
            createdAt: startedAt,
            updatedAt: startedAt
        )
        mutateDatabase { database in
            database.focusSessions.append(session)
        }
        plannedActivityDraft = ""
        statusMessage = "已开始专注。"
        return true
    }

    func pauseFocus() {
        guard let index = activeSessionIndex else {
            return
        }
        guard database.focusSessions[index].isPaused == false else {
            return
        }

        let pausedAt = Date()
        mutateDatabase { database in
            database.focusSessions[index].pauseIntervals.append(PauseInterval(startedAt: pausedAt))
            database.focusSessions[index].refreshActiveDuration(now: pausedAt)
        }
        statusMessage = "专注已暂停。"
    }

    func resumeFocus() {
        guard let index = activeSessionIndex else {
            return
        }
        guard let lastPauseIndex = database.focusSessions[index].pauseIntervals.indices.last,
              database.focusSessions[index].pauseIntervals[lastPauseIndex].endedAt == nil else {
            return
        }

        let resumedAt = Date()
        mutateDatabase { database in
            database.focusSessions[index].pauseIntervals[lastPauseIndex].endedAt = resumedAt
            database.focusSessions[index].refreshActiveDuration(now: resumedAt)
        }
        statusMessage = "专注已继续。"
    }

    @discardableResult
    func finishFocus() -> Bool {
        guard let index = activeSessionIndex else {
            return false
        }

        let actualActivity = finishActivityDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard actualActivity.isEmpty == false else {
            statusMessage = "结束前需要记录实际做了什么。"
            return false
        }

        let endedAt = Date()
        mutateDatabase { database in
            if let lastPauseIndex = database.focusSessions[index].pauseIntervals.indices.last,
               database.focusSessions[index].pauseIntervals[lastPauseIndex].endedAt == nil {
                database.focusSessions[index].pauseIntervals[lastPauseIndex].endedAt = endedAt
            }
            database.focusSessions[index].actualActivity = actualActivity
            database.focusSessions[index].endedAt = endedAt
            database.focusSessions[index].refreshActiveDuration(now: endedAt)
        }
        finishActivityDraft = ""
        statusMessage = "专注已保存。"
        return true
    }

    @discardableResult
    func addQuickNote() -> Bool {
        let content = quickNoteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard content.isEmpty == false else {
            statusMessage = "先写一点内容。"
            return false
        }

        let occurredAt = Date()
        mutateDatabase { database in
            database.quickNotes.append(QuickNote(content: content, occurredAt: occurredAt))
        }
        quickNoteDraft = ""
        statusMessage = "碎碎念已记录。"
        return true
    }

    @discardableResult
    func updateEntryText(_ entry: DayEntry, to rawText: String) -> Bool {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else {
            statusMessage = "内容不能为空。"
            return false
        }

        switch entry {
        case .focusSession(let session):
            guard session.endedAt != nil else {
                statusMessage = "进行中的专注不能编辑。"
                return false
            }
            mutateDatabase { database in
                if let index = database.focusSessions.firstIndex(where: { $0.id == session.id }) {
                    database.focusSessions[index].actualActivity = text
                    database.focusSessions[index].updatedAt = Date()
                }
            }
        case .quickNote(let note):
            mutateDatabase { database in
                if let index = database.quickNotes.firstIndex(where: { $0.id == note.id }) {
                    database.quickNotes[index].content = text
                    database.quickNotes[index].updatedAt = Date()
                }
            }
        }
        statusMessage = "已更新一条记录。"
        return true
    }

    func deleteEntry(_ entry: DayEntry) {
        switch entry {
        case .focusSession(let session):
            guard session.endedAt != nil else {
                statusMessage = "进行中的专注不能删除。"
                return
            }
            mutateDatabase { database in
                database.focusSessions.removeAll { $0.id == session.id }
            }
        case .quickNote(let note):
            mutateDatabase { database in
                database.quickNotes.removeAll { $0.id == note.id }
            }
        }
        statusMessage = "已删除一条记录。"
    }

    func exportToday() {
        do {
            let exportDatabase = databaseWithRefreshedActiveDuration()
            let result = try exporter.export(date: now, database: exportDatabase, settings: settings)
            statusMessage = "已导出：\(result.fileURL.path)"
        } catch {
            statusMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    func chooseExportDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择"
        panel.message = "选择一日一笺 Markdown 的导出目录"
        panel.directoryURL = existingDirectoryForPanel()
        panel.level = .modalPanel

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if panel.runModal() == .OK, let url = panel.url {
            settings.exportDirectoryPath = url.path
            saveSettings()
            statusMessage = "导出目录已更新。"
        } else {
            statusMessage = "未修改导出目录。"
        }
    }

    private func existingDirectoryForPanel() -> URL {
        let resolvedURL = settings.resolvedExportDirectoryURL()
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return resolvedURL
        }

        let parentURL = resolvedURL.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: parentURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return parentURL
        }

        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private var activeSessionIndex: Int? {
        database.focusSessions.firstIndex { $0.endedAt == nil }
    }

    private func load() {
        do {
            database = try store.loadDatabase()
            settings = try store.loadSettings()
        } catch {
            statusMessage = "读取本地数据失败：\(error.localizedDescription)"
        }
    }

    private func saveDatabase() {
        do {
            try store.saveDatabase(database)
        } catch {
            statusMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func saveSettings() {
        do {
            try store.saveSettings(settings)
        } catch {
            statusMessage = "保存设置失败：\(error.localizedDescription)"
        }
    }

    private func mutateDatabase(_ mutation: (inout DayLogDatabase) -> Void) {
        var nextDatabase = database
        mutation(&nextDatabase)
        database = nextDatabase
        saveDatabase()
    }

    private func databaseWithRefreshedActiveDuration() -> DayLogDatabase {
        var copy = database
        if let index = copy.focusSessions.firstIndex(where: { $0.endedAt == nil }) {
            copy.focusSessions[index].refreshActiveDuration(now: now)
        }
        return copy
    }

    private func startTicker() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
    }
}
