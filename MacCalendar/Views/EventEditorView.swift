import SwiftUI

/// Editable working copy of an event used by the editor sheet.
struct EventDraft {
    var title: String
    var location: String
    var notes: String
    var startDate: Date
    var endDate: Date
    var reminderEnabled: Bool
    var reminderOffset: TimeInterval

    struct ReminderChoice: Identifiable {
        let label: String
        let offset: TimeInterval
        var id: TimeInterval { offset }
    }

    static let reminderChoices: [ReminderChoice] = [
        ReminderChoice(label: "准时", offset: 0),
        ReminderChoice(label: "提前 5 分钟", offset: 5 * 60),
        ReminderChoice(label: "提前 15 分钟", offset: 15 * 60),
        ReminderChoice(label: "提前 30 分钟", offset: 30 * 60),
        ReminderChoice(label: "提前 1 小时", offset: 60 * 60),
        ReminderChoice(label: "提前 1 天", offset: 24 * 60 * 60)
    ]

    init(from event: CalendarEvent? = nil, initialDay: Date? = nil, calendar: Calendar = .current) {
        if let event {
            title = event.title
            location = event.location
            notes = event.notes
            startDate = event.startDate
            endDate = event.endDate
            reminderEnabled = event.reminderEnabled
            reminderOffset = event.reminderOffset
        } else {
            let base = initialDay ?? Date()
            let day = calendar.startOfDay(for: base)
            let hour = calendar.component(.hour, from: base)
            // New events default to the top of the next hour relative to "now",
            // but stay anchored on the clicked day when one was supplied.
            let roundedNow = calendar.date(
                bySettingHour: min(hour + 1, 23),
                minute: 0,
                second: 0,
                of: Date()
            ) ?? Date()
            startDate = initialDay == nil
                ? roundedNow
                : calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? base
            endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate.addingTimeInterval(3600)
            title = ""
            location = ""
            notes = ""
            reminderEnabled = true
            reminderOffset = 15 * 60
        }
    }
}

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let existingEvent: CalendarEvent?
    private let onSave: (EventDraft) -> Void

    @State private var draft: EventDraft
    @State private var validationError: EventValidator.ValidationError?

    init(event: CalendarEvent?, initialDay: Date?, onSave: @escaping (EventDraft) -> Void) {
        self.existingEvent = event
        self.onSave = onSave
        _draft = State(initialValue: EventDraft(from: event, initialDay: initialDay))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(existingEvent == nil ? "新建事件" : "编辑事件")
                .font(.title2.bold())
                .padding(.bottom, 16)

            Form {
                Section {
                    TextField("标题", text: $draft.title)
                    TextField("地点（可选）", text: $draft.location)
                }

                Section {
                    DatePicker("开始", selection: $draft.startDate)
                    DatePicker("结束", selection: $draft.endDate)
                }

                Section {
                    Toggle("提醒", isOn: $draft.reminderEnabled)
                    if draft.reminderEnabled {
                        Picker("提醒时间", selection: $draft.reminderOffset) {
                            ForEach(Self.choices, id: \.offset) { choice in
                                Text(choice.label).tag(choice.offset)
                            }
                        }
                    }
                }

                Section {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if draft.notes.isEmpty {
                                Text("备注（可选）")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }
            }
            .formStyle(.grouped)

            if let validationError {
                Label(validationError.errorDescription ?? "", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .padding(.horizontal)
            }

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 460, height: 560)
    }

    private static let choices = EventDraft.reminderChoices

    private func save() {
        switch EventValidator.validate(
            title: draft.title,
            startDate: draft.startDate,
            endDate: draft.endDate
        ) {
        case .success:
            onSave(draft)
            dismiss()
        case .failure(let error):
            validationError = error
        }
    }
}
