import SwiftUI

/// Monday-to-Sunday (or locale-first) weekday labels derived from the current calendar.
struct WeekdayHeaderView: View {
    private let symbols: [String] = {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }()

    var body: some View {
        HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

struct MonthGridView: View {
    let days: [Date]
    let currentVisibleDate: Date
    let events: [CalendarEvent]
    let onSelectDay: (Date) -> Void
    let onSelectEvent: (CalendarEvent) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        GeometryReader { proxy in
            let rowHeight = proxy.size.height / 6
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(days, id: \.self) { day in
                    MonthDayCell(
                        day: day,
                        visibleMonth: currentVisibleDate,
                        events: CalendarMath.events(events, on: day, calendar: .current),
                        onSelectDay: { onSelectDay(day) },
                        onSelectEvent: onSelectEvent
                    )
                    .frame(height: rowHeight - 1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

private struct MonthDayCell: View {
    @Environment(\.calendar) private var environmentCalendar

    let day: Date
    let visibleMonth: Date
    let events: [CalendarEvent]
    let onSelectDay: () -> Void
    let onSelectEvent: (CalendarEvent) -> Void

    private var calendar: Calendar { environmentCalendar }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if calendar.isDateInToday(day) {
                    Text(day, format: .dateTime.day())
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Circle().fill(.red))
                } else {
                    Text(day, format: .dateTime.day())
                        .font(.caption)
                        .foregroundStyle(
                            CalendarMath.isSameMonth(day, visibleMonth, calendar: calendar)
                                ? .primary : .secondary
                        )
                        .padding(5)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 1) {
                ForEach(events.prefix(3), id: \.identifier) { event in
                    EventChipView(event: event)
                        .onTapGesture { onSelectEvent(event) }
                }
                if events.count > 3 {
                    Text(
                        String(
                            localized: "另有 \(events.count - 3) 项",
                            comment: "More events indicator on a month cell"
                        )
                    )
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CalendarTheme.dayCellBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CalendarTheme.gridSeparator, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelectDay() }
    }
}

private struct EventChipView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(.accent)
                .frame(width: 5, height: 5)
            Text(event.title)
                .font(.system(size: 10))
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.accent.opacity(0.15))
        )
    }
}

struct WeekView: View {
    let days: [Date]
    let events: [CalendarEvent]
    let onSelectEvent: (CalendarEvent) -> Void

    var body: some View {
        HStack(spacing: 1) {
            ForEach(days, id: \.self) { day in
                WeekDayColumn(
                    day: day,
                    events: CalendarMath.events(events, on: day, calendar: .current),
                    onSelectEvent: onSelectEvent
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

private struct WeekDayColumn: View {
    @Environment(\.calendar) private var environmentCalendar

    let day: Date
    let events: [CalendarEvent]
    let onSelectEvent: (CalendarEvent) -> Void

    private var calendar: Calendar { environmentCalendar }

    var body: some View {
        VStack(spacing: 2) {
            Text(day, format: .dateTime.day())
                .font(.caption.bold())
                .foregroundStyle(calendar.isDateInToday(day) ? .red : .primary)
                .padding(.vertical, 4)

            ForEach(events, id: \.identifier) { event in
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title)
                        .font(.system(size: 10))
                        .lineLimit(2)
                    Text(event.startDate, format: .dateTime.hour().minute())
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.accent.opacity(0.15))
                )
                .onTapGesture { onSelectEvent(event) }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(CalendarTheme.dayCellBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CalendarTheme.gridSeparator, lineWidth: 0.5)
        )
    }
}

struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.subheadline)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(event.startDate, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if event.reminderEnabled {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            if !event.location.isEmpty {
                Label(event.location, systemImage: "mappin.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
