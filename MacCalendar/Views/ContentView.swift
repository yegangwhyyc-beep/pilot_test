import SwiftUI
import SwiftData

enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case month
    case week

    var id: String { rawValue }

    var label: String {
        switch self {
        case .month: return String(localized: "月", comment: "Month view picker label")
        case .week: return String(localized: "周", comment: "Week view picker label")
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationController: NotificationController

    @Query(sort: \CalendarEvent.startDate, order: .forward) private var allEvents: [CalendarEvent]

    @State private var displayMode: CalendarDisplayMode = .month
    @State private var visibleDate = Date()
    @State private var searchText = ""
    @State private var editorTarget: EditorTarget?
    @State private var selectedEvent: CalendarEvent?

    private enum EditorTarget: Identifiable {
        case new(day: Date?)
        case edit(CalendarEvent)

        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let event): return event.identifier.uuidString
            }
        }
    }

    private var visibleEvents: [CalendarEvent] {
        CalendarMath.search(allEvents, text: searchText)
    }

    var body: some View {
        HStack(spacing: 0) {
            calendarPane
            Divider()
            sidebar
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    visibleDate = Date()
                } label: {
                    Text("今天", comment: "Toolbar: jump to today")
                }

                Picker(
                    String(localized: "视图", comment: "View mode picker accessibility label"),
                    selection: $displayMode
                ) {
                    ForEach(CalendarDisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 90)

                Button {
                    shift(-1)
                } label: {
                    Label("上一个", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }

                Button {
                    shift(1)
                } label: {
                    Label("下一个", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }

                Button {
                    editorTarget = .new(day: nil)
                } label: {
                    Label("新建事件", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editorTarget) { target in
            switch target {
            case .new(let day):
                EventEditorView(event: nil, initialDay: day) { draft in
                    save(draft)
                }
            case .edit(let event):
                EventEditorView(event: event, initialDay: nil) { draft in
                    update(event, with: draft)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event) { action in
                switch action {
                case .edit:
                    editorTarget = .edit(event)
                case .delete:
                    delete(event)
                }
            }
        }
        .task {
            await notificationController.requestAuthorizationIfNeeded()
        }
    }

    @ViewBuilder private var calendarPane: some View {
        VStack(spacing: 0) {
            Text(heading, format: .dateTime.year().month())
                .font(.title2.bold())
                .padding(.vertical, 12)
            WeekdayHeaderView()
            switch displayMode {
            case .month:
                MonthGridView(
                    days: CalendarMath.monthGridDays(containing: visibleDate, calendar: .current),
                    currentVisibleDate: visibleDate,
                    events: visibleEvents,
                    onSelectDay: { day in
                        editorTarget = .new(day: day)
                    },
                    onSelectEvent: { event in
                        selectedEvent = event
                    }
                )
            case .week:
                WeekView(
                    days: CalendarMath.weekDays(containing: visibleDate, calendar: .current),
                    events: visibleEvents,
                    onSelectEvent: { event in
                        selectedEvent = event
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("事件", comment: "Sidebar title")
                .font(.headline)
            TextField(
                String(localized: "搜索标题、地点或备注", comment: "Search field placeholder"),
                text: $searchText
            )
            .textFieldStyle(.roundedBorder)

            if visibleEvents.isEmpty {
                Spacer()
                Text("暂无事件", comment: "Empty events list")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List(visibleEvents) { event in
                    EventRowView(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                        .contextMenu {
                            Button(String(localized: "编辑", comment: "Context menu edit")) {
                                editorTarget = .edit(event)
                            }
                            Button(String(localized: "删除", comment: "Context menu delete"), role: .destructive) {
                                delete(event)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .padding()
        .frame(width: 280)
    }

    private var heading: Date {
        displayMode == .week
            ? CalendarMath.weekDays(containing: visibleDate, calendar: .current).first ?? visibleDate
            : visibleDate
    }

    private func shift(_ direction: Int) {
        switch displayMode {
        case .month:
            visibleDate = CalendarMath.addMonths(direction, to: visibleDate, calendar: .current) ?? visibleDate
        case .week:
            visibleDate = CalendarMath.addWeeks(direction, to: visibleDate, calendar: .current) ?? visibleDate
        }
    }

    // MARK: - Persistence

    private func save(_ draft: EventDraft) {
        let event = CalendarEvent(
            title: draft.title,
            location: draft.location,
            notes: draft.notes,
            startDate: draft.startDate,
            endDate: draft.endDate,
            reminderEnabled: draft.reminderEnabled,
            reminderOffset: draft.reminderOffset
        )
        modelContext.insert(event)
        do {
            try modelContext.save()
        } catch {
            return
        }
        Task { await notificationController.scheduleReminder(for: event) }
    }

    private func update(_ event: CalendarEvent, with draft: EventDraft) {
        event.title = draft.title
        event.location = draft.location
        event.notes = draft.notes
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.reminderEnabled = draft.reminderEnabled
        event.reminderOffset = draft.reminderOffset
        try? modelContext.save()
        notificationController.cancelReminder(for: event.identifier)
        Task { await notificationController.scheduleReminder(for: event) }
    }

    private func delete(_ event: CalendarEvent) {
        notificationController.cancelReminder(for: event.identifier)
        modelContext.delete(event)
        try? modelContext.save()
    }
}
