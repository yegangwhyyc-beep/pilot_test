import Foundation

/// Pure calendar-grid math. All operations take an explicit calendar so tests are deterministic
/// regardless of the user's region (tests use a fixed GMT calendar).
enum CalendarMath {
    /// Days displayed in a month view: the complete week rows that contain the month,
    /// Monday-first (42 cells = 6 rows) or Sunday-first per the supplied calendar.
    static func monthGridDays(containing date: Date, calendar: Calendar) -> [Date] {
        let interval = monthInterval(containing: date, calendar: calendar)
        let firstWeekday = calendar.firstWeekday
        let weekdayOfFirst = calendar.component(.weekday, from: interval.start)
        var lead = weekdayOfFirst - firstWeekday
        if lead < 0 { lead += 7 }

        guard let gridStart = calendar.date(byAdding: .day, value: -lead, to: interval.start) else {
            return []
        }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    /// The seven days of the week containing `date`, starting on the calendar's first weekday.
    static func weekDays(containing date: Date, calendar: Calendar) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    /// Half-open `[start, end)` interval of the month containing `date`.
    static func monthInterval(containing date: Date, calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: date, duration: 0)
    }

    static func startOfDay(_ date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isSameDay(_ a: Date, _ b: Date, calendar: Calendar) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    static func isSameMonth(_ a: Date, _ b: Date, calendar: Calendar) -> Bool {
        calendar.isDate(a, equalTo: b, toGranularity: .month)
    }

    static func addMonths(_ value: Int, to date: Date, calendar: Calendar) -> Date? {
        calendar.date(byAdding: .month, value: value, to: date)
    }

    static func addWeeks(_ value: Int, to date: Date, calendar: Calendar) -> Date? {
        calendar.date(byAdding: .weekOfYear, value: value, to: date)
    }

    /// Filters events that fall at least partially within the given day (day-boundary based).
    static func events<E: CalendarEventProtocol>(_ events: [E], on day: Date, calendar: Calendar) -> [E] {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return events
            .filter { $0.eventStart < dayEnd && dayStart < $0.eventEnd }
            .sorted { $0.eventStart < $1.eventStart }
    }

    /// Case-insensitive search over title, location and notes.
    static func search<E: CalendarEventProtocol>(_ events: [E], text: String) -> [E] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return events.sorted { $0.eventStart < $1.eventStart } }
        return events
            .filter {
                $0.eventTitle.localizedCaseInsensitiveContains(needle)
                    || $0.eventLocation.localizedCaseInsensitiveContains(needle)
                    || $0.eventNotes.localizedCaseInsensitiveContains(needle)
            }
            .sorted { $0.eventStart < $1.eventStart }
    }
}

/// Minimal read-only projection of an event used by pure logic and its unit tests,
/// so the math layer does not depend on SwiftData model objects.
protocol CalendarEventProtocol {
    var eventTitle: String { get }
    var eventLocation: String { get }
    var eventNotes: String { get }
    var eventStart: Date { get }
    var eventEnd: Date { get }
}
