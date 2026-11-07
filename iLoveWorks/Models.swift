//
//  Models.swift
//  iLoveWorks
//
//  API models. Property names are camelCase; APIClient decodes with .convertFromSnakeCase,
//  so never add snake_case CodingKeys here (they would never match).
//

import Foundation

enum UserRole: String, Codable {
    case admin
    case worker
}

struct User: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    let avatarUrl: String?
    let lastSeenAt: String?
    let createdAt: String?
}

struct LoginResponse: Codable {
    let user: User
    let accessToken: String
    let tokenType: String?
}

struct TimeEntry: Codable, Identifiable {
    let id: String
    let userId: String?
    let clockIn: String
    let clockOut: String?
    let durationSeconds: Double?
    let activity: String?

    var seconds: Int { Int(durationSeconds ?? 0) }
}

struct TaskItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let price: Double
    let status: String // assigned, in_progress, completed
    let assigneeId: String
    let assigneeName: String?
    let frequency: String? // once, daily, weekly, monthly
    let payoutSchedule: String? // per_task, daily, weekly, monthly
    let dueAt: String?
    let dueTime: String?
    let adminAlarm: String?
    let userAlarm: String?
    let dueDayOfWeek: Int? // 0 = Monday … 6 = Sunday
    let estimatedHours: Double?
    let dailyHours: Double?
    let completedAt: String?

    var isCompleted: Bool { status == "completed" }
}

struct Announcement: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let tag: String?
    let createdAt: String?
}

struct GoalReaction: Codable, Hashable {
    let emoji: String
    let byId: String
    let byName: String?
    let at: String?
}

struct Goal: Codable, Identifiable {
    let id: String
    let ownerId: String
    let kind: String? // goal, trip
    let title: String
    let targetAmount: Double?
    let productLink: String?
    let imageUrl: String?
    let period: String?
    let status: String
    let progress: GoalProgress?
    let collaboratorIds: [String]?
    let createdAt: String?
    let owner: User?
    var reactions: [GoalReaction]?

    struct GoalProgress: Codable {
        let today: Double?
        let week: Double?
        let month: Double?
        let year: Double?
        let periodAmount: Double?
        let pctOfTarget: Double?
    }

    var pct: Double { progress?.pctOfTarget ?? 0 }
    var weekAmount: Double { progress?.week ?? 0 }
}

struct Essential: Codable, Identifiable {
    let id: String
    let ownerId: String
    let title: String
    let price: Double
    let quantity: Int
    let category: String
    let note: String?
    let purchased: Bool
    let recurring: Bool?
    let dueDate: String?
    let completedAt: String?
    let collaboratorIds: [String]?
    let createdBy: String?
    let createdAt: String?
    let imageUrl: String?
    let owner: User?
}

struct Award: Codable, Identifiable {
    let code: String
    let title: String
    let description: String
    let icon: String
    let earned: Bool
    let earnedAt: String?

    var id: String { code }
}

struct AwardResponse: Codable {
    let items: [Award]
    let earnedCount: Int?
    let total: Int?
}

struct NotificationItem: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String?
    let link: String?
    let read: Bool
    let createdAt: String?
}

struct NotificationsResponse: Codable {
    let items: [NotificationItem]
    let unread: Int
}

struct WeeklyDay: Codable {
    let day: String?
    let count: Int
    let earned: Double
    let hours: Double
    let titles: [String]?
}

struct WeeklyActivityResponse: Codable {
    let streakDays: Int
    let completionsByDay: [WeeklyDay]
}

struct DailyCompletion: Codable {
    let day: String?
    let count: Int
    let earned: Double?
    let hours: Double?
    let titles: [String]?
}

struct WorkerStatus: Codable, Identifiable {
    let worker: User
    let online: Bool
    let lastSeenAt: String?
    let currentlyClockedIn: Bool
    let activeActivity: String?
    let isIdle: Bool?
    let idleMinutes: Int?
    let todayWorkedHours: Double
    let weekWorkedHours: Double
    let dailyRequiredHours: Double
    let weeklyRequiredHours: Double
    let todayLeftHours: Double?
    let weekLeftHours: Double?
    let potentialWeekly: Double
    let potentialMonthly: Double
    let openTasksCount: Int
    let streakDays: Int
    let completionsByDay: [DailyCompletion]?
    let inconsistencies: Inconsistencies?

    var id: String { worker.id }

    struct Inconsistencies: Codable {
        let missedDays: [String]
        let lowDays: [String]
        let streakBroken: Bool
        let totalIssues: Int

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            missedDays = (try? c.decode([String].self, forKey: .missedDays)) ?? []
            lowDays = (try? c.decode([String].self, forKey: .lowDays)) ?? []
            streakBroken = (try? c.decode(Bool.self, forKey: .streakBroken)) ?? false
            totalIssues = (try? c.decode(Int.self, forKey: .totalIssues)) ?? 0
        }
    }
}

struct PayrollRow: Codable, Identifiable {
    let worker: User
    let tasksCompleted: Int
    let tasksEarnings: Double
    let totalHours: Double
    let currentlyClockedIn: Bool?

    var id: String { worker.id }
}

// MARK: - Sizes

enum AnyValue: Codable, Equatable {
    case string(String)
    case double(Double)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let x = try? c.decode(Double.self) { self = .double(x) }
        else if let x = try? c.decode(String.self) { self = .string(x) }
        else if let x = try? c.decode(Bool.self) { self = .string(x ? "Yes" : "No") }
        else { throw DecodingError.typeMismatch(AnyValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported size value")) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let x): try c.encode(x)
        case .double(let x): try c.encode(x)
        }
    }

    var doubleValue: Double? {
        if case .double(let x) = self { return x }
        return nil
    }

    var stringValue: String {
        switch self {
        case .string(let x): return x
        case .double(let x): return SizeHelper.fmtNum(x)
        }
    }
}

struct SizesActor: Codable {
    let id: String?
    let name: String?
    let role: String?
}

struct SizesDoc: Codable {
    let id: String?
    let userId: String?
    let fit: String?
    let units: String?
    let values: [String: AnyValue]
    let updatedAt: String?
    let createdAt: String?
    let updatedBy: SizesActor?
}

struct SizeChange: Codable {
    let key: String
    let label: String
}

struct SizesSaveResponse: Codable {
    let sizes: SizesDoc
    let changes: [SizeChange]?
    let notified: Bool?
}

struct WorkerSizesResponse: Codable {
    let worker: User
    let sizes: SizesDoc
}

// MARK: - Holiday themes

struct ThemeInfo: Codable, Equatable {
    let name: String
    let greeting: String
    let emoji: String
    let emojis: [String]
}

struct ThemeOption: Codable, Identifiable, Equatable {
    let key: String
    let name: String
    let greeting: String?
    let emoji: String
    var id: String { key }
}

struct ThemeWindow: Codable, Identifiable, Equatable {
    let key: String
    let name: String
    let emoji: String
    let date: String
    let starts: String
    let ends: String
    var id: String { key + date }
}

struct ThemeState: Codable, Equatable {
    let mode: String
    let effective: String
    let theme: ThemeInfo?
    let autoSuggestion: String?
    let endsOn: String?
    let windowDays: Int?
    let themes: [ThemeOption]?
    let upcoming: [ThemeWindow]?
}

/// Accepts any JSON body (used for endpoints whose response we ignore).
struct EmptyResponse: Decodable {
    init(from decoder: Decoder) throws {}
}
