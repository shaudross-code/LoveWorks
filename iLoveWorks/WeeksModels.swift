//
//  WeeksModels.swift
//  iLoveWorks
//
//  Week-by-week payroll, paid marks, task history and crew health (same numbers as the web app).
//

import Foundation

struct PayoutInfo: Codable, Hashable {
    let amount: Double
    let tasksCompleted: Int?
    let hours: Double?
    let paidAt: String?
    let paidByName: String?
    let note: String?
}

struct WeekDayTotals: Codable, Hashable {
    let date: String
    let count: Int
    let earned: Double
    let hours: Double
}

struct PayrollWeekRow: Codable, Identifiable {
    let worker: User
    let tasksCompleted: Int
    let earned: Double
    let hours: Double
    let days: [WeekDayTotals]
    let payout: PayoutInfo?
    let changedSincePaid: Bool

    var id: String { worker.id }
}

struct PayrollWeekTotals: Codable {
    let earned: Double
    let paid: Double
    let unpaid: Double
    let tasksCompleted: Int
    let hours: Double
}

struct PayrollWeek: Codable {
    let weekStart: String
    let weekLastDay: String
    let isCurrent: Bool
    let isFuture: Bool
    let rows: [PayrollWeekRow]
    let totals: PayrollWeekTotals
}

struct PayrollSheetStatus: Codable {
    let configured: Bool
    let url: String?
    let synced: Int
    let pending: Int
    let error: String?
}

struct MarkPaidRequest: Encodable {
    let workerIds: [String]?  // nil = everyone with pay that week
}

struct MarkPaidResponse: Decodable {
    let ok: Bool
    let marked: Int
}

struct SheetSyncResponse: Decodable {
    let ok: Bool
    let synced: Int
    let url: String?
}

struct HistoryTask: Codable, Hashable {
    let taskId: String?
    let title: String
    let price: Double
    let completedAt: String
}

struct HistoryDay: Codable, Hashable {
    let date: String
    let count: Int
    let earned: Double
    let hours: Double
    let tasks: [HistoryTask]
}

struct HistoryWeek: Codable, Identifiable {
    let weekStart: String
    let weekLastDay: String
    let tasksCompleted: Int
    let earned: Double
    let hours: Double
    let payout: PayoutInfo?
    let days: [HistoryDay]

    var id: String { weekStart }
}

struct HistoryWeeksResponse: Codable {
    let weeks: [HistoryWeek]
    let nextBefore: String
    let hasMore: Bool
    let tz: String?
}

struct CrewHealthDay: Codable, Hashable {
    let date: String
    let activeKcal: Double?
    let totalKcal: Double?
    let weightKg: Double?
}

struct CrewHealthRow: Codable, Identifiable {
    let worker: User
    let shared: Bool
    let days: [CrewHealthDay]?
    let daysWithData: Int?
    let activeTotal: Double?
    let totalTotal: Double?
    let activeAvg: Double?
    let totalAvg: Double?
    let latestWeightKg: Double?
    let latestWeightDate: String?
    let weightSource: String?
    let weightChangeKg: Double?

    var id: String { worker.id }
}

struct CrewHealthWeek: Codable {
    let weekStart: String
    let weekLastDay: String
    let isCurrent: Bool
    let rows: [CrewHealthRow]
}

/// Week ids are the Monday's date (yyyy-MM-dd) in the business timezone, as sent by the server.
enum WeekMath {
    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func date(_ s: String) -> Date { parser.date(from: s) ?? Date() }

    private static func format(_ s: String, _ pattern: String) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.setLocalizedDateFormatFromTemplate(pattern)
        return f.string(from: date(s))
    }

    static func shift(_ weekStart: String, by weeks: Int) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return parser.string(from: cal.date(byAdding: .day, value: 7 * weeks, to: date(weekStart)) ?? date(weekStart))
    }

    static func day(_ s: String) -> String { format(s, "MMMd") }
    static func weekday(_ s: String) -> String { format(s, "EEE") }

    static func label(_ start: String, _ last: String) -> String {
        let sameMonth = start.prefix(7) == last.prefix(7)
        return "\(day(start)) – \(sameMonth ? format(last, "d") : day(last))"
    }

    static func money(_ v: Double) -> String { String(format: "$%.2f", v) }
}
