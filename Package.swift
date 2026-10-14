// swift-tools-version: 5.9
//
// Cross-platform test entry for the app's pure-logic layer.
//
// The Xcode project (MacCalendar.xcodeproj) remains the canonical build on
// macOS:  xcodebuild -project MacCalendar.xcodeproj -scheme MacCalendar test
//
// This package exists so the same logic unit tests can also run on Linux
// Swift (no Xcode):  swift test
// It compiles ONLY MacCalendar/Utilities (CalendarMath + EventValidator — no
// SwiftUI/SwiftData/AppKit imports) against the SAME source files and the
// SAME XCTest cases in MacCalendarTests/ that the macOS test target uses.
import PackageDescription

let package = Package(
    name: "MacCalendar",
    targets: [
        .target(name: "MacCalendar", path: "MacCalendar/Utilities"),
        .testTarget(
            name: "MacCalendarTests",
            dependencies: ["MacCalendar"],
            path: "MacCalendarTests",
            exclude: ["MacCalendarTests.entitlements"]
        )
    ]
)
