import Foundation

/// Validation rules shared by the event editor UI and unit tests.
///
/// `public` so the same source file builds into both the app target (Xcode) and the
/// SwiftPM `MacCalendar` library used by `swift test` and the `CalendarDemo` CLI.
public enum EventValidator {
    public static func validate(
        title: String,
        startDate: Date,
        endDate: Date
    ) -> Result<Void, ValidationError> {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyTitle) }
        guard endDate > startDate else { return .failure(.endNotAfterStart) }
        return .success(())
    }

    public enum ValidationError: LocalizedError, Equatable {
        case emptyTitle
        case endNotAfterStart

        public var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return NSLocalizedString("事件标题不能为空。", comment: "Validation: empty title")
            case .endNotAfterStart:
                return NSLocalizedString("结束时间必须晚于开始时间。", comment: "Validation: end before start")
            }
        }

        public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
            switch (lhs, rhs) {
            case (.emptyTitle, .emptyTitle), (.endNotAfterStart, .endNotAfterStart):
                return true
            default:
                return false
            }
        }
    }
}
