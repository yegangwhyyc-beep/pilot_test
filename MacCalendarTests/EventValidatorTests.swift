import XCTest
@testable import MacCalendar

final class EventValidatorTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_789_000_000)
    private var end: Date { start.addingTimeInterval(3600) }

    private func assertFailure(
        _ result: Result<Void, EventValidator.ValidationError>,
        equals expected: EventValidator.ValidationError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case .success:
            XCTFail("Expected failure \(expected), got success", file: file, line: line)
        case .failure(let actual):
            XCTAssertEqual(actual, expected, file: file, line: line)
        }
    }

    func testAcceptsValidEvent() {
        switch EventValidator.validate(title: "Meeting", startDate: start, endDate: end) {
        case .success:
            break
        case .failure(let error):
            XCTFail("Expected success, got \(error)")
        }
    }

    func testRejectsEmptyAndWhitespaceOnlyTitle() {
        assertFailure(
            EventValidator.validate(title: "", startDate: start, endDate: end),
            equals: .emptyTitle
        )
        assertFailure(
            EventValidator.validate(title: "   \n\t ", startDate: start, endDate: end),
            equals: .emptyTitle
        )
    }

    func testRejectsEndAtOrBeforeStart() {
        assertFailure(
            EventValidator.validate(title: "x", startDate: start, endDate: start),
            equals: .endNotAfterStart
        )
        assertFailure(
            EventValidator.validate(title: "x", startDate: end, endDate: start),
            equals: .endNotAfterStart
        )
    }
}
