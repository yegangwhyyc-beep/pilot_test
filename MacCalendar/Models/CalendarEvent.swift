import Foundation
import SwiftData

/// A single calendar event. Persisted locally with SwiftData (no cloud sync in v1).
@Model
final class CalendarEvent {
    /// Stable identifier used for notification scheduling and diffing.
    @Attribute(.unique) var identifier: UUID
    var title: String
    var location: String
    var notes: String
    var startDate: Date
    var endDate: Date
    /// Whether a user notification reminder is requested.
    var reminderEnabled: Bool
    /// Reminder lead time in seconds before ``startDate`` (e.g. 300 = 5 minutes).
    var reminderOffset: TimeInterval
    var createdAt: Date

    init(
        identifier: UUID = UUID(),
        title: String,
        location: String = "",
        notes: String = "",
        startDate: Date,
        endDate: Date,
        reminderEnabled: Bool = true,
        reminderOffset: TimeInterval = 15 * 60,
        createdAt: Date = .now
    ) {
        self.identifier = identifier
        self.title = title
        self.location = location
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.reminderEnabled = reminderEnabled
        self.reminderOffset = reminderOffset
        self.createdAt = createdAt
    }

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var reminderDate: Date? {
        guard reminderEnabled, reminderOffset >= 0 else { return nil }
        return startDate.addingTimeInterval(-reminderOffset)
    }

    func overlaps(_ other: CalendarEvent) -> Bool {
        startDate < other.endDate && other.startDate < endDate
    }
}

extension CalendarEvent: CalendarEventProtocol {
    var eventTitle: String { title }
    var eventLocation: String { location }
    var eventNotes: String { notes }
    var eventStart: Date { startDate }
    var eventEnd: Date { endDate }
}
