import Foundation

public struct PauseInterval: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?

    public init(id: UUID = UUID(), startedAt: Date, endedAt: Date? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public func durationSeconds(until now: Date) -> Int {
        let end = endedAt ?? now
        return max(0, Int(end.timeIntervalSince(startedAt)))
    }
}

public struct FocusSession: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var plannedActivity: String?
    public var actualActivity: String
    public var startedAt: Date
    public var endedAt: Date?
    public var pauseIntervals: [PauseInterval]
    public var activeDurationSeconds: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        plannedActivity: String? = nil,
        actualActivity: String = "",
        startedAt: Date,
        endedAt: Date? = nil,
        pauseIntervals: [PauseInterval] = [],
        activeDurationSeconds: Int = 0,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.plannedActivity = plannedActivity?.nilIfBlank
        self.actualActivity = actualActivity
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.pauseIntervals = pauseIntervals
        self.activeDurationSeconds = activeDurationSeconds
        self.createdAt = createdAt ?? startedAt
        self.updatedAt = updatedAt ?? startedAt
    }

    public var isCompleted: Bool {
        endedAt != nil
    }

    public var isPaused: Bool {
        pauseIntervals.last?.endedAt == nil && pauseIntervals.last != nil
    }

    public func activeDuration(until now: Date = Date()) -> Int {
        let end = endedAt ?? now
        let grossDuration = max(0, Int(end.timeIntervalSince(startedAt)))
        let pausedDuration = pauseIntervals.reduce(0) { partial, interval in
            partial + interval.durationSeconds(until: end)
        }
        return max(0, grossDuration - pausedDuration)
    }

    public mutating func refreshActiveDuration(now: Date = Date()) {
        activeDurationSeconds = activeDuration(until: now)
        updatedAt = now
    }
}

public struct QuickNote: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var content: String
    public var occurredAt: Date
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        content: String,
        occurredAt: Date,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.occurredAt = occurredAt
        self.createdAt = createdAt ?? occurredAt
        self.updatedAt = updatedAt ?? occurredAt
    }
}

public enum DayEntry: Codable, Equatable, Identifiable, Sendable {
    case focusSession(FocusSession)
    case quickNote(QuickNote)

    private enum CodingKeys: String, CodingKey {
        case type
        case focusSession
        case quickNote
    }

    public var id: UUID {
        switch self {
        case .focusSession(let session):
            session.id
        case .quickNote(let note):
            note.id
        }
    }

    public var occurredAt: Date {
        switch self {
        case .focusSession(let session):
            session.startedAt
        case .quickNote(let note):
            note.occurredAt
        }
    }

    public var typeLabel: String {
        switch self {
        case .focusSession:
            "Focus"
        case .quickNote:
            "Note"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "focusSession":
            self = .focusSession(try container.decode(FocusSession.self, forKey: .focusSession))
        case "quickNote":
            self = .quickNote(try container.decode(QuickNote.self, forKey: .quickNote))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unsupported day entry type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .focusSession(let session):
            try container.encode("focusSession", forKey: .type)
            try container.encode(session, forKey: .focusSession)
        case .quickNote(let note):
            try container.encode("quickNote", forKey: .type)
            try container.encode(note, forKey: .quickNote)
        }
    }
}

public struct DayleafDatabase: Codable, Equatable, Sendable {
    public var focusSessions: [FocusSession]
    public var quickNotes: [QuickNote]

    public init(focusSessions: [FocusSession] = [], quickNotes: [QuickNote] = []) {
        self.focusSessions = focusSessions
        self.quickNotes = quickNotes
    }

    public func entries(on date: Date, calendar: Calendar = .current) -> [DayEntry] {
        let focusEntries = focusSessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
            .map(DayEntry.focusSession)
        let noteEntries = quickNotes
            .filter { calendar.isDate($0.occurredAt, inSameDayAs: date) }
            .map(DayEntry.quickNote)

        return (focusEntries + noteEntries).sorted { left, right in
            if left.occurredAt == right.occurredAt {
                return left.typeLabel < right.typeLabel
            }
            return left.occurredAt < right.occurredAt
        }
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
