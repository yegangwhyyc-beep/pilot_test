import XCTest
@testable import MacCalendar

private struct FixtureEvent: CalendarEventProtocol {
    let eventTitle: String
    let eventLocation: String
    let eventNotes: String
    let eventStart: Date
    let eventEnd: Date
}

final class CalendarMathTests: XCTestCase {
    /// Gregorian, Sunday-first, UTC — deterministic regardless of the runner's region.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        var components = DateComponents()
        components.year = y
        components.month = m
        components.day = d
        components.hour = h
        components.minute = min
        components.timeZone = TimeZone(identifier: "UTC")
        return calendar.date(from: components)!
    }

    func testMonthGridContainsSixWeeksAndStartsOnGridFirstWeekday() {
        // October 2026: the 1st is a Thursday. Sunday-first grid starts Sep 27.
        let days = CalendarMath.monthGridDays(containing: date(2026, 10, 15), calendar: calendar)
        XCTAssertEqual(days.count, 42)
        XCTAssertEqual(calendar.component(.weekday, from: days[0]), calendar.firstWeekday)
        XCTAssertTrue(calendar.isDate(days[0], inSameDayAs: date(2026, 9, 27)))
        XCTAssertTrue(calendar.isDate(days[41], inSameDayAs: date(2026, 11, 7)))
    }

    func testMonthGridCoversMonthThatStartsOnFirstWeekday() {
        // February 2026 starts on a Sunday; the grid starts exactly on Feb 1.
        let days = CalendarMath.monthGridDays(containing: date(2026, 2, 10), calendar: calendar)
        XCTAssertTrue(calendar.isDate(days[0], inSameDayAs: date(2026, 2, 1)))
        XCTAssertTrue(calendar.isDate(days[41], inSameDayAs: date(2026, 3, 14)))
    }

    func testWeekDaysReturnsSevenConsecutiveDaysStartingOnFirstWeekday() {
        // Wednesday Oct 14, 2026 -> week starts Sunday Oct 11.
        let days = CalendarMath.weekDays(containing: date(2026, 10, 14), calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(calendar.isDate(days[0], inSameDayAs: date(2026, 10, 11)))
        for (index, day) in days.enumerated() where index > 0 {
            let gap = calendar.dateComponents([.day], from: days[index - 1], to: day).day
            XCTAssertEqual(gap, 1)
        }
    }

    func testEventsOnDayIncludesEventsThatStartOrEndOnThatDay() {
        let day = date(2026, 10, 12)
        let inside = FixtureEvent(
            eventTitle: "a", eventLocation: "", eventNotes: "",
            eventStart: date(2026, 10, 12, 9), eventEnd: date(2026, 10, 12, 10)
        )
        let startsOnDay = FixtureEvent(
            eventTitle: "b", eventLocation: "", eventNotes: "",
            eventStart: date(2026, 10, 12, 23), eventEnd: date(2026, 10, 13, 1)
        )
        let endsAtMidnight = FixtureEvent(
            eventTitle: "c", eventLocation: "", eventNotes: "",
            eventStart: date(2026, 10, 11, 23), eventEnd: date(2026, 10, 12, 0)
        )
        let otherDay = FixtureEvent(
            eventTitle: "d", eventLocation: "", eventNotes: "",
            eventStart: date(2026, 10, 13, 9), eventEnd: date(2026, 10, 13, 10)
        )

        let result = CalendarMath.events(
            [otherDay, endsAtMidnight, startsOnDay, inside],
            on: day,
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.eventTitle), ["a", "b"])
    }

    func testEventsOnDayIsSortedByStartTime() {
        let later = FixtureEvent(
            eventTitle: "later", eventLocation: "", eventNotes: "",
            eventStart: date(2026, 10, 12, 15), eventEnd: date(2026, 10, 12, 16)
        )
        let earlier = FixtureEvent(
            eventTitle: "earlier", eventLocation: "", eventNotes: "",
            eventStart: date(2026, 10, 12, 8), eventEnd: date(2026, 10, 12, 9)
        )
        let result = CalendarMath.events([later, earlier], on: date(2026, 10, 12), calendar: calendar)
        XCTAssertEqual(result.map(\.eventTitle), ["earlier", "later"])
    }

    func testSearchMatchesTitleLocationAndNotesCaseInsensitively() {
        let events = [
            FixtureEvent(eventTitle: "Team Standup", eventLocation: "Room 3", eventNotes: "weekly", eventStart: date(2026, 10, 12, 9), eventEnd: date(2026, 10, 12, 10)),
            FixtureEvent(eventTitle: "Lunch", eventLocation: "Cafe Milano", eventNotes: "", eventStart: date(2026, 10, 12, 12), eventEnd: date(2026, 10, 12, 13)),
            FixtureEvent(eventTitle: "Doctor", eventLocation: "", eventNotes: "bring prior report", eventStart: date(2026, 10, 14, 9), eventEnd: date(2026, 10, 14, 10))
        ]

        XCTAssertEqual(
            CalendarMath.search(events, text: "standup").map(\.eventTitle),
            ["Team Standup"]
        )
        XCTAssertEqual(
            CalendarMath.search(events, text: "MILANO").map(\.eventTitle),
            ["Lunch"]
        )
        XCTAssertEqual(
            CalendarMath.search(events, text: "report").map(\.eventTitle),
            ["Doctor"]
        )
    }

    func testSearchWithBlankTextReturnsAllSorted() {
        let later = FixtureEvent(eventTitle: "b", eventLocation: "", eventNotes: "", eventStart: date(2026, 10, 13), eventEnd: date(2026, 10, 13, 1))
        let earlier = FixtureEvent(eventTitle: "a", eventLocation: "", eventNotes: "", eventStart: date(2026, 10, 12), eventEnd: date(2026, 10, 12, 1))
        XCTAssertEqual(
            CalendarMath.search([later, earlier], text: "   ").map(\.eventTitle),
            ["a", "b"]
        )
    }

    func testAddMonthsHandlesYearBoundary() {
        let result = CalendarMath.addMonths(3, to: date(2026, 11, 20), calendar: calendar)
        XCTAssertTrue(calendar.isDate(result!, inSameDayAs: date(2027, 2, 20)))
    }

    func testSameDayAndSameMonthComparisons() {
        XCTAssertTrue(CalendarMath.isSameDay(date(2026, 10, 12, 1), date(2026, 10, 12, 23), calendar: calendar))
        XCTAssertFalse(CalendarMath.isSameDay(date(2026, 10, 12), date(2026, 10, 13), calendar: calendar))
        XCTAssertTrue(CalendarMath.isSameMonth(date(2026, 10, 1), date(2026, 10, 31), calendar: calendar))
        XCTAssertFalse(CalendarMath.isSameMonth(date(2026, 10, 31), date(2026, 11, 1), calendar: calendar))
    }
}
