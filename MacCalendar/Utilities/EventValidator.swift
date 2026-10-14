import Foundation

/// Validation rules shared by the event editor UI and unit tests.
enum EventValidator {
    static func validate(
        title: String,
        startDate: Date,
        endDate: Date
    ) -> Result<Void, ValidationError> {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyTitle) }
        guard endDate > startDate else { return .failure(.endNotAfterStart) }
        return .success(())
    }

    enum ValidationError: LocalizedError, Equatable {
        case emptyTitle
        case endNotAfterStart

        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return NSLocalizedString("事件标题不能为空。", comment: "Validation: empty title")
            case .endNotAfterStart:
                return NSLocalizedString("结束时间必须晚于开始时间。", comment: "Validation: end before start")
            }
        }

        static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
            switch (lhs, rhs) {
            case (.emptyTitle, .emptyTitle), (.endNotAfterStart, .endNotAfterStart):
                return true
            default:
                return false
            }
        }
    }
}
