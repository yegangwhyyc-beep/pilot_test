import SwiftUI
import SwiftData

@main
struct MacCalendarApp: App {
    @StateObject private var notificationController = NotificationController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationController)
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(for: CalendarEvent.self)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .environmentObject(notificationController)
        }
    }
}
