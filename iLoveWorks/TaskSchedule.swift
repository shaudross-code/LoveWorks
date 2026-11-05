//
//  TaskSchedule.swift
//  iLoveWorks
//
//  Same deadline rules as the web dashboard: a task with only a due weekday is due on the next
//  occurrence of that weekday (today counts), at its due time or end of day.
//

import Foundation

enum Weekday {
    static let names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    static let short = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    static func label(_ dow: Int?) -> String? {
        guard let d = dow, (0...6).contains(d) else { return nil }
        return short[d]
    }

    /// Monday = 0 … Sunday = 6
    static func index(of date: Date, calendar: Calendar = .current) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }
}

struct DeadlineBuckets {
    var overdue: [TaskItem] = []
    var dueToday: [TaskItem] = []
    var dueThisWeek: [TaskItem] = []
    var later: [TaskItem] = []
    var weeklyPotential: Double = 0
    var openTotal: Double = 0
}

enum TaskSchedule {
    static func effectiveDue(_ task: TaskItem, now: Date = Date(), calendar: Calendar = .current) -> Date? {
        if let due = APIDate.parse(task.dueAt) { return due }
        guard let dow = task.dueDayOfWeek, (0...6).contains(dow) else { return nil }
        let today = calendar.startOfDay(for: now)
        let ahead = (dow - Weekday.index(of: now, calendar: calendar) + 7) % 7
        guard let day = calendar.date(byAdding: .day, value: ahead, to: today) else { return nil }
        let parts = (task.dueTime ?? "23:59").split(separator: ":").compactMap { Int($0) }
        let h = parts.first ?? 23, m = parts.count > 1 ? parts[1] : 59
        return calendar.date(bySettingHour: h, minute: m, second: 59, of: day)
    }

    static func buckets(_ tasks: [TaskItem], now: Date = Date(), calendar: Calendar = .current) -> DeadlineBuckets {
        var b = DeadlineBuckets()
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!.addingTimeInterval(-0.001)
        let weekStart = calendar.date(byAdding: .day, value: -Weekday.index(of: now, calendar: calendar), to: todayStart)!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!.addingTimeInterval(-0.001)
        for t in tasks where !t.isCompleted {
            b.openTotal += t.price
            guard let due = effectiveDue(t, now: now, calendar: calendar) else { b.later.append(t); continue }
            if due < todayStart { b.overdue.append(t) }
            else if due <= todayEnd { b.dueToday.append(t) }
            else if due <= weekEnd { b.dueThisWeek.append(t) }
            else { b.later.append(t) }
            if due >= weekStart && due <= weekEnd { b.weeklyPotential += t.price }
        }
        return b
    }

    /// Short "Mon · by 18:00" style label for task rows.
    static func dueLabel(_ task: TaskItem) -> String? {
        var parts: [String] = []
        if let d = Weekday.label(task.dueDayOfWeek) { parts.append(d) }
        else if task.dueAt != nil, (task.frequency ?? "once") == "once" { parts.append(APIDate.day(task.dueAt)) }
        if let t = task.dueTime, !t.isEmpty { parts.append("by \(t)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
