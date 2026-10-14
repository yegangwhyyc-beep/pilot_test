import Foundation
import UserNotifications

/// Schedules and cancels local user-notification reminders for events.
@MainActor
final class NotificationController: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    /// Schedules (or replaces) the reminder notification for an event.
    /// Past reminder dates are ignored. Returns true when a request was scheduled.
    @discardableResult
    func scheduleReminder(for event: CalendarEvent) async -> Bool {
        guard let fireDate = event.reminderDate, fireDate > .now else { return false }
        guard await requestAuthorizationIfNeeded() else { return false }

        let content = UNMutableNotificationContent()
        content.title = event.title
        if !event.location.isEmpty {
            content.subtitle = event.location
        }
        if !event.notes.isEmpty {
            content.body = event.notes
        }
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.requestIdentifier(for: event.identifier),
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func cancelReminder(for eventID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier(for: eventID)])
    }

    func cancelAllReminders() async {
        center.removeAllPendingNotificationRequests()
    }

    static func requestIdentifier(for eventID: UUID) -> String {
        "maccalendar.event-reminder.\(eventID.uuidString)"
    }
}

extension NotificationController: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
