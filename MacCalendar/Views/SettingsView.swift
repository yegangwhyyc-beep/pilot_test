import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notificationController: NotificationController

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("通知权限")
                    Spacer()
                    Text(statusText)
                        .foregroundStyle(.secondary)
                }
                Button("请求通知权限") {
                    Task { await notificationController.requestAuthorizationIfNeeded() }
                }
                Button("刷新状态") {
                    Task { await notificationController.refreshAuthorizationStatus() }
                }
            } footer: {
                Text("提醒通过 macOS 用户通知在本地发送，不会上传任何数据。")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 220)
        .task {
            await notificationController.refreshAuthorizationStatus()
        }
    }

    private var statusText: String {
        switch notificationController.authorizationStatus {
        case .notDetermined:
            return String(localized: "未决定", comment: "Notification status: not determined")
        case .denied:
            return String(localized: "已拒绝（请在系统设置中开启）", comment: "Notification status: denied")
        case .authorized:
            return String(localized: "已授权", comment: "Notification status: authorized")
        case .provisional:
            return String(localized: "临时授权", comment: "Notification status: provisional")
        case .ephemeral:
            return String(localized: "临时", comment: "Notification status: ephemeral")
        @unknown default:
            return String(localized: "未知", comment: "Notification status: unknown")
        }
    }
}
