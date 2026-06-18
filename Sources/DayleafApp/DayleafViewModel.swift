import AppKit
import DayleafCore
import Foundation
import SwiftUI

@MainActor
final class DayleafViewModel: ObservableObject {
    @Published private(set) var database = DayleafDatabase()
    @Published private(set) var settings = DayleafSettings()
    @Published var plannedActivityDraft = ""
    @Published var quickNoteDraft = ""
    @Published var finishActivityDraft = ""
    @Published var aiBaseURLDraft = ""
    @Published var aiModelDraft = ""
    @Published var aiAPIKeyDraft = ""
    @Published private(set) var hasStoredAPIKey = false
    @Published private(set) var isGeneratingJournal = false
    @Published private(set) var quickCaptureShortcutRegistrationMessage: String?
    @Published var selectedJournalID: UUID?
    @Published var statusMessage: String?
    @Published var now = Date()

    private let store: JSONDayleafStore
    private let exporter: MarkdownExporter
    private let pdfExporter: PDFDailyExporter
    private let promptBuilder: JournalPromptBuilder
    private let aiClient: OpenAICompatibleClient
    private let apiKeyStore: APIKeyStore
    private var timer: Timer?

    init(
        store: JSONDayleafStore = .live(),
        exporter: MarkdownExporter = MarkdownExporter(),
        pdfExporter: PDFDailyExporter = PDFDailyExporter(),
        promptBuilder: JournalPromptBuilder = JournalPromptBuilder(),
        aiClient: OpenAICompatibleClient = OpenAICompatibleClient(),
        apiKeyStore: APIKeyStore = APIKeyStore()
    ) {
        self.store = store
        self.exporter = exporter
        self.pdfExporter = pdfExporter
        self.promptBuilder = promptBuilder
        self.aiClient = aiClient
        self.apiKeyStore = apiKeyStore
        load()
        startTicker()
    }

    var menuTitle: String {
        guard let activeSession else {
            return ""
        }
        return Self.menuDurationText(activeSession.activeDurationSeconds)
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

    var quickCaptureShortcut: KeyboardShortcutSpec {
        settings.resolvedQuickCaptureShortcut
    }

    var quickCaptureShortcutDisplay: String {
        quickCaptureShortcut.displayText
    }

    var journalsNewestFirst: [DailyJournal] {
        database.journalsNewestFirst
    }

    var selectedJournal: DailyJournal? {
        if let selectedJournalID,
           let journal = database.journals.first(where: { $0.id == selectedJournalID }) {
            return journal
        }
        return journalsNewestFirst.first
    }

    var todayJournal: DailyJournal? {
        database.journal(on: now)
    }

    var aiConfigurationMessage: String? {
        if settings.aiBaseURL?.nilIfBlank == nil || settings.aiModel?.nilIfBlank == nil {
            return "请先填写 AI Base URL 和 Model。"
        }
        if hasStoredAPIKey == false {
            return "请先保存 AI Key。"
        }
        return nil
    }

    var isAIConfigured: Bool {
        aiConfigurationMessage == nil
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
        let saved = mutateDatabase { database in
            database.quickNotes.append(QuickNote(content: content, occurredAt: occurredAt))
        }
        guard saved else {
            return false
        }

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

    func copyTodayForAI() {
        let exportDatabase = databaseWithRefreshedActiveDuration()
        let markdown = exporter.markdown(for: now, database: exportDatabase, exportedAt: now)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if pasteboard.setString(markdown, forType: .string) {
            statusMessage = "已复制给 AI"
        } else {
            statusMessage = "复制失败：无法写入剪贴板"
        }
    }

    func saveAISettings() {
        settings.aiBaseURL = aiBaseURLDraft.nilIfBlank
        settings.aiModel = aiModelDraft.nilIfBlank
        saveSettings()
        statusMessage = "AI 设置已保存。"
    }

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

    func saveAIAPIKey() {
        let key = aiAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if key.isEmpty {
                try apiKeyStore.deleteKey()
                hasStoredAPIKey = false
                statusMessage = "AI Key 已清空。"
            } else {
                try apiKeyStore.saveKey(key)
                hasStoredAPIKey = true
                aiAPIKeyDraft = ""
                statusMessage = "AI Key 已保存到 Keychain。"
            }
        } catch {
            statusMessage = "保存 AI Key 失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    func generateJournalForToday() -> Bool {
        guard isGeneratingJournal == false else {
            return true
        }
        guard settings.aiBaseURL?.nilIfBlank != nil, settings.aiModel?.nilIfBlank != nil else {
            statusMessage = "请先填写 AI Base URL 和 Model。"
            return false
        }

        let exportDatabase = databaseWithRefreshedActiveDuration()
        guard let prompt = promptBuilder.prompt(for: now, database: exportDatabase, generatedAt: now) else {
            statusMessage = "今天还没有可成文的记录。"
            return false
        }
        if let existing = exportDatabase.journal(on: now), existing.editedByUser {
            statusMessage = "这篇日记已手动编辑，暂不直接覆盖。"
            selectedJournalID = existing.id
            return true
        }

        let apiKey: String
        do {
            guard let loadedKey = try apiKeyStore.loadKey()?.nilIfBlank else {
                hasStoredAPIKey = false
                statusMessage = "请先保存 AI Key。"
                return false
            }
            apiKey = loadedKey
            hasStoredAPIKey = true
        } catch {
            statusMessage = "读取 AI Key 失败：\(error.localizedDescription)"
            return false
        }

        isGeneratingJournal = true
        statusMessage = "正在一笺成文…"

        Task {
            do {
                let content = try await aiClient.generateJournal(settings: settings, apiKey: apiKey, prompt: prompt)
                await MainActor.run {
                    self.upsertGeneratedJournal(content: content, sourceEntryIDs: prompt.sourceEntryIDs)
                    self.isGeneratingJournal = false
                    self.statusMessage = "今日一笺已生成。"
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingJournal = false
                    self.statusMessage = "一笺成文失败：\(error.localizedDescription)"
                }
            }
        }
        return true
    }

    func refreshAPIKeyStatus() {
        do {
            hasStoredAPIKey = (try apiKeyStore.loadKey()?.nilIfBlank) != nil
        } catch {
            statusMessage = "读取 AI Key 失败：\(error.localizedDescription)"
        }
    }

    func selectJournal(_ journal: DailyJournal) {
        selectedJournalID = journal.id
    }

    @discardableResult
    func updateJournal(_ journal: DailyJournal, title: String, content: String) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false, trimmedContent.isEmpty == false else {
            statusMessage = "日记标题和正文不能为空。"
            return false
        }

        mutateDatabase { database in
            if let index = database.journals.firstIndex(where: { $0.id == journal.id }) {
                database.journals[index].title = trimmedTitle
                database.journals[index].content = trimmedContent
                database.journals[index].editedByUser = true
                database.journals[index].updatedAt = Date()
            }
        }
        selectedJournalID = journal.id
        statusMessage = "日记已保存。"
        return true
    }

    func deleteJournal(_ journal: DailyJournal) {
        mutateDatabase { database in
            database.journals.removeAll { $0.id == journal.id }
        }
        selectedJournalID = journalsNewestFirst.first?.id
        statusMessage = "日记已删除。"
    }

    func exportJournalPDF(_ journal: DailyJournal) {
        do {
            let result = try pdfExporter.export(journal: journal, settings: settings)
            statusMessage = "日记 PDF 已保存：\(result.fileURL.path)"
        } catch {
            statusMessage = "日记 PDF 保存失败：\(error.localizedDescription)"
        }
    }

    func saveTodayPDF() {
        do {
            let exportDatabase = databaseWithRefreshedActiveDuration()
            _ = try pdfExporter.export(date: now, database: exportDatabase, settings: settings, exportedAt: now)
            statusMessage = "PDF 已保存"
        } catch {
            statusMessage = "PDF 保存失败：\(error.localizedDescription)"
        }
    }

    func chooseExportDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择"
        panel.message = "选择一日一笺 PDF 的保存目录"
        panel.directoryURL = existingDirectoryForPanel()
        panel.level = .modalPanel

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if panel.runModal() == .OK, let url = panel.url {
            settings.exportDirectoryPath = url.path
            saveSettings()
            statusMessage = "保存目录已更新。"
        } else {
            statusMessage = "未修改保存目录。"
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
            aiBaseURLDraft = settings.aiBaseURL ?? "https://api.openai.com/v1"
            aiModelDraft = settings.aiModel ?? ""
            hasStoredAPIKey = (try apiKeyStore.loadKey()?.nilIfBlank) != nil
            selectedJournalID = database.journalsNewestFirst.first?.id
        } catch {
            statusMessage = "读取本地数据失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    private func saveDatabase(_ databaseToSave: DayleafDatabase? = nil) -> Bool {
        do {
            try store.saveDatabase(databaseToSave ?? database)
            return true
        } catch {
            statusMessage = "保存失败：\(error.localizedDescription)"
            return false
        }
    }

    private func saveSettings() {
        do {
            try store.saveSettings(settings)
        } catch {
            statusMessage = "保存设置失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    private func mutateDatabase(_ mutation: (inout DayleafDatabase) -> Void) -> Bool {
        var nextDatabase = database
        mutation(&nextDatabase)
        guard saveDatabase(nextDatabase) else {
            return false
        }
        database = nextDatabase
        return true
    }

    private func upsertGeneratedJournal(content: String, sourceEntryIDs: [UUID]) {
        let generatedAt = Date()
        let day = Calendar.current.startOfDay(for: now)
        let title = "\(Self.dateTitle(day)) 今日一笺"
        let modelName = settings.aiModel ?? ""

        mutateDatabase { database in
            if let index = database.journals.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
                database.journals[index].title = title
                database.journals[index].content = content
                database.journals[index].sourceEntryIDs = sourceEntryIDs
                database.journals[index].generatedAt = generatedAt
                database.journals[index].updatedAt = generatedAt
                database.journals[index].editedByUser = false
                database.journals[index].modelName = modelName
                selectedJournalID = database.journals[index].id
            } else {
                let journal = DailyJournal(
                    date: day,
                    title: title,
                    content: content,
                    sourceEntryIDs: sourceEntryIDs,
                    generatedAt: generatedAt,
                    modelName: modelName
                )
                database.journals.append(journal)
                selectedJournalID = journal.id
            }
        }
    }

    private func databaseWithRefreshedActiveDuration() -> DayleafDatabase {
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

    private static func menuDurationText(_ seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        guard totalMinutes >= 60 else {
            return "\(totalMinutes) \(totalMinutes == 1 ? "min" : "mins")"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)\(minutes == 1 ? "min" : "mins")"
    }

    private static func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
