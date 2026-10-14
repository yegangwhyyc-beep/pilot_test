//
//  CalendarDemo
//  不依赖 Xcode 的命令行演示：链接 App 的真实业务逻辑库
//  （MacCalendar/Utilities/CalendarMath.swift、EventValidator.swift，
//  见根 Package.swift 的 MacCalendar target），
//  用固定 UTC 日历打印 2026 年 10 月月视图、按天事件、搜索与表单校验结果。
//
//  运行：swift run CalendarDemo
//

import Foundation
import MacCalendar

struct DemoEvent: CalendarEventProtocol {
    let eventTitle: String
    let eventLocation: String
    let eventNotes: String
    let eventStart: Date
    let eventEnd: Date
}

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "UTC")!
calendar.locale = Locale(identifier: "zh_CN")
calendar.firstWeekday = 2 // 周一开头，符合中文使用习惯

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
    c.timeZone = TimeZone(identifier: "UTC")
    return calendar.date(from: c)!
}

let events: [DemoEvent] = [
    DemoEvent(eventTitle: "团队站会", eventLocation: "3 号会议室", eventNotes: "每周例会",
              eventStart: date(2026, 10, 12, 9, 0), eventEnd: date(2026, 10, 12, 9, 30)),
    DemoEvent(eventTitle: "产品评审", eventLocation: "线上", eventNotes: "带上原型",
              eventStart: date(2026, 10, 14, 14, 0), eventEnd: date(2026, 10, 14, 15, 30)),
    DemoEvent(eventTitle: "跨天发布值守", eventLocation: "机房", eventNotes: "",
              eventStart: date(2026, 10, 15, 23, 0), eventEnd: date(2026, 10, 16, 2, 0)),
    DemoEvent(eventTitle: "看牙医", eventLocation: "口腔诊所", eventNotes: "带既往报告",
              eventStart: date(2026, 10, 20, 10, 0), eventEnd: date(2026, 10, 20, 11, 0))
]

let weekdayCN = ["日", "一", "二", "三", "四", "五", "六"]
func format(_ day: Date) -> String {
    let comps = calendar.dateComponents([.month, .day, .weekday], from: day)
    let w = weekdayCN[(comps.weekday ?? 1) - 1]
    return "\(comps.month!)月\(comps.day!)日 周\(w)"
}

print("==================================================")
print(" MacCalendar 命令行演示（直接编译 App 真实逻辑）")
print("==================================================")

let anchor = date(2026, 10, 15)
print("\n【月视图】2026 年 10 月（42 格，周一起；[dd]=当日有事件）")
let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
print(weekdays.map { " \($0) " }.joined(separator: " "))
let grid = CalendarMath.monthGridDays(containing: anchor, calendar: calendar)
for (index, day) in grid.enumerated() {
    let dayNum = calendar.component(.day, from: day)
    let inMonth = CalendarMath.isSameMonth(day, anchor, calendar: calendar)
    let hasEvent = !CalendarMath.events(events, on: day, calendar: calendar).isEmpty
    let label = inMonth
        ? (hasEvent ? String(format: "[%2d]", dayNum) : String(format: " %2d ", dayNum))
        : String(format: "  %2d", dayNum)
    print(label, terminator: index % 7 == 6 ? "\n" : " ")
}

print("\n【周视图】\(format(anchor)) 所在周")
for day in CalendarMath.weekDays(containing: anchor, calendar: calendar) {
    let todays = CalendarMath.events(events, on: day, calendar: calendar)
    let names = todays.map(\.eventTitle).joined(separator: "、")
    print("  \(format(day))：\(names.isEmpty ? "—" : names)")
}

print("\n【翻月】2026-11-20 加 3 个月 =")
if let d = CalendarMath.addMonths(3, to: date(2026, 11, 20), calendar: calendar) {
    print("  \(format(d))")
}

print("\n【搜索】关键字 \"报告\"（匹配备注，大小写/中英文不敏感）")
for e in CalendarMath.search(events, text: "报告") {
    print("  ✓ \(e.eventTitle) @ \(e.eventLocation)")
}

print("\n【表单校验】")
func check(_ title: String, _ s: Date, _ e: Date) {
    switch EventValidator.validate(title: title, startDate: s, endDate: e) {
    case .success:
        print("  ✓ \"\(title)\" 校验通过")
    case .failure(let err):
        print("  ✗ \"\(title)\" -> \(err.errorDescription ?? "无效")")
    }
}
let s = date(2026, 10, 14, 9, 0)
check("有效会议", s, date(2026, 10, 14, 10, 0))
check("   ", s, date(2026, 10, 14, 10, 0))
check("时间颠倒", date(2026, 10, 14, 11, 0), s)

print("\n演示结束。GUI（SwiftUI）部分只能在 macOS 构建运行；")
print("此处运行的月网格/周/过滤/搜索/校验与 App 内是同一份源码。")
