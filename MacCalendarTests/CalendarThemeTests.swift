import XCTest
import SwiftUI
import AppKit
@testable import MacCalendar

final class CalendarThemeTests: XCTestCase {
    private func srgbComponents(of color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let resolved = NSColor(color).usingColorSpace(.sRGB)!
        return (resolved.redComponent, resolved.greenComponent, resolved.blueComponent, resolved.alphaComponent)
    }

    private func assertIsBlueTint(_ color: Color, file: StaticString = #filePath, line: UInt = #line) {
        let components = srgbComponents(of: color)
        XCTAssertGreaterThan(components.blue, components.red, "Calendar background must be blue-tinted", file: file, line: line)
        XCTAssertGreaterThan(components.blue, components.green, "Calendar background must be blue-tinted", file: file, line: line)
        XCTAssertGreaterThan(components.alpha, 0, "Calendar background must be visible", file: file, line: line)
    }

    func testCalendarBackgroundsAreBlueTinted() {
        assertIsBlueTint(CalendarTheme.calendarPaneBackground)
        assertIsBlueTint(CalendarTheme.dayCellBackground)
    }

    func testCalendarBackgroundsShareTheSameBlueHue() {
        let pane = srgbComponents(of: CalendarTheme.calendarPaneBackground)
        let cell = srgbComponents(of: CalendarTheme.dayCellBackground)
        XCTAssertEqual(pane.red, cell.red, accuracy: 0.001)
        XCTAssertEqual(pane.green, cell.green, accuracy: 0.001)
        XCTAssertEqual(pane.blue, cell.blue, accuracy: 0.001)
    }
}
