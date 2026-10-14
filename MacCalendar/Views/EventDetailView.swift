import SwiftUI

enum EventDetailAction {
    case edit
    case delete
}

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent
    let onAction: (EventDetailAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.title)
                .font(.title2.bold())

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(
                    "\(event.startDate, format: .dateTime.year().month().day().weekday()) · \(event.startDate, format: .dateTime.hour().minute()) – \(event.endDate, format: .dateTime.hour().minute())"
                )
            }

            if !event.location.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                    Text(event.location)
                }
            }

            if event.reminderEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                    Text(reminderText)
                }
            }

            if !event.notes.isEmpty {
                Divider()
                ScrollView {
                    Text(event.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }

            Spacer()

            HStack {
                Button(role: .destructive) {
                    onAction(.delete)
                    dismiss()
                } label: {
                    Label("删除", systemImage: "trash")
                }
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("编辑") {
                    onAction(.edit)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 360)
    }

    private var reminderText: String {
        let minutes = Int(event.reminderOffset / 60)
        if minutes == 0 {
            return String(localized: "事件开始时提醒", comment: "Reminder summary: at start")
        } else if minutes < 60 {
            return String(localized: "提前 \(minutes) 分钟提醒", comment: "Reminder summary: minutes")
        } else if minutes < 1440 {
            return String(localized: "提前 \(minutes / 60) 小时提醒", comment: "Reminder summary: hours")
        } else {
            return String(localized: "提前 \(minutes / 1440) 天提醒", comment: "Reminder summary: days")
        }
    }
}
