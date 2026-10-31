//
//  WorkerViewModel.swift
//  iLoveWorks
//

import SwiftUI
import Combine

struct TimeEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let clockIn: String
    let clockOut: String?
    let durationSeconds: Int
    let activity: String
    
    enum CodingKeys: String, CodingKey {
        case id, activity
        case userId = "user_id"
        case clockIn = "clock_in"
        case clockOut = "clock_out"
        case durationSeconds = "duration_seconds"
    }
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
    let dueDayOfWeek: Int?
    let estimatedHours: Double?
    let dailyHours: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, price, status, frequency
        case assigneeId = "assignee_id"
        case assigneeName = "assignee_name"
        case payoutSchedule = "payout_schedule"
        case dueAt = "due_at"
        case dueTime = "due_time"
        case dueDayOfWeek = "due_day_of_week"
        case estimatedHours = "estimated_hours"
        case dailyHours = "daily_hours"
    }
}

struct Announcement: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let tag: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, tag
        case createdAt = "created_at"
    }
}

struct Goal: Codable, Identifiable {
    let id: String
    let ownerId: String
    let kind: String // goal, trip
    let title: String
    let targetAmount: Double?
    let productLink: String?
    let status: String
    let progress: GoalProgress
    let collaboratorIds: [String]
    let createdAt: String
    
    struct GoalProgress: Codable {
        let week: Double
        let month: Double
        let year: Double
        let total: Double
        let pctOfTarget: Double?
        
        enum CodingKeys: String, CodingKey {
            case week, month, year, total
            case pctOfTarget = "pct_of_target"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, status, progress, kind, createdAt = "created_at"
        case ownerId = "owner_id"
        case productLink = "product_link"
        case collaboratorIds = "collaborator_ids"
        case targetAmount = "target_amount"
    }
}

struct Essential: Codable, Identifiable {
    let id: String
    let ownerId: String
    let title: String
    let price: Double
    let quantity: Int
    let category: String // household, everyday, groceries, personal, kids, other
    let note: String?
    let purchased: Bool
    let recurring: Bool
    let dueDate: String?
    let completedAt: String?
    let collaboratorIds: [String]
    let createdBy: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, price, quantity, category, note, purchased, recurring, createdAt = "created_at"
        case ownerId = "owner_id"
        case dueDate = "due_date"
        case completedAt = "completed_at"
        case collaboratorIds = "collaborator_ids"
        case createdBy = "created_by"
    }
}

struct Award: Codable, Identifiable {
    let code: String
    let title: String
    let description: String
    let icon: String
    let earned: Bool
    let earnedAt: String?
    
    var id: String { code }
    
    enum CodingKeys: String, CodingKey {
        case code, title, description, icon, earned
        case earnedAt = "earned_at"
    }
}

struct NotificationItem: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String?
    let read: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, body, read
        case createdAt = "created_at"
    }
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
    let titles: [String]
}

struct WeeklyActivityResponse: Codable {
    let streakDays: Int
    let completionsByDay: [WeeklyDay]
    
    enum CodingKeys: String, CodingKey {
        case streakDays = "streak_days"
        case completionsByDay = "completions_by_day"
    }
}

struct AnyCodable: Codable {}

class WorkerViewModel: ObservableObject {
    @Published var activeEntries: [TimeEntry] = []
    @Published var tasks: [TaskItem] = []
    @Published var allEntries: [TimeEntry] = []
    @Published var goals: [Goal] = []
    @Published var trips: [Goal] = []
    @Published var essentials: [Essential] = []
    @Published var awards: [Award] = []
    @Published var announcements: [Announcement] = []
    @Published var notifications: [NotificationItem] = []
    @Published var unreadNotificationsCount: Int = 0
    @Published var weeklyActivity: [WeeklyDay] = []
    @Published var streakDays: Int = 0
    
    @Published var liveSeconds: Int = 0
    @Published var todayHours: Double = 0.0
    @Published var now = Date()
    
    private var timer: Timer?
    
    func loadData() {
        Task {
            do {
                async let active: [TimeEntry] = try await APIClient.shared.request("/time/active")
                async let fetchedTasks: [TaskItem] = try await APIClient.shared.request("/tasks")
                async let fetchedEntries: [TimeEntry] = try await APIClient.shared.request("/time/entries")
                async let fetchedGoals: [Goal] = try await APIClient.shared.request("/goals?kind=goal")
                async let fetchedTrips: [Goal] = try await APIClient.shared.request("/goals?kind=trip")
                async let fetchedEssentials: [Essential] = try await APIClient.shared.request("/essentials")
                async let fetchedAnnouncements: [Announcement] = try await APIClient.shared.request("/announcements")
                async let fetchedNotifs: NotificationsResponse = try await APIClient.shared.request("/notifications")
                async let fetchedActivity: WeeklyActivityResponse = try await APIClient.shared.request("/me/weekly-activity")
                async let fetchedAwardsResponse: AwardResponse = try await APIClient.shared.request("/awards")
                
                let resActive = try await active
                let resTasks = try await fetchedTasks
                let resEntries = try await fetchedEntries
                let resGoals = try await fetchedGoals
                let resTrips = try await fetchedTrips
                let resEssentials = try await fetchedEssentials
                let resAnnouncements = try await fetchedAnnouncements
                let resNotifs = try await fetchedNotifs
                let resActivity = try await fetchedActivity
                let resAwards = try await fetchedAwardsResponse
                
                await MainActor.run {
                    self.activeEntries = resActive
                    self.tasks = resTasks
                    self.allEntries = resEntries
                    self.goals = resGoals
                    self.trips = resTrips
                    self.essentials = resEssentials
                    self.awards = resAwards.items
                    self.announcements = resAnnouncements
                    self.notifications = resNotifs.items
                    self.unreadNotificationsCount = resNotifs.unread
                    self.weeklyActivity = resActivity.completionsByDay
                    self.streakDays = resActivity.streakDays
                    
                    self.calculateTodayHours()
                    self.startTimer()
                }
            } catch {
                print("Failed to load worker data: \(error)")
            }
        }
    }
    
    private func calculateTodayHours() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        var totalSeconds = 0
        
        // Sum completed entries from today
        for entry in allEntries {
            if let outDate = entry.clockOut, let outDt = formatter.date(from: outDate), outDt >= startOfToday {
                totalSeconds += entry.durationSeconds
            }
        }
        
        // Add live seconds from all concurrent active clocks
        for entry in activeEntries {
            if let inDt = formatter.date(from: entry.clockIn) {
                let currentLive = Int(Date().timeIntervalSince(inDt))
                totalSeconds += max(0, currentLive)
            }
        }
        
        self.todayHours = Double(totalSeconds) / 3600.0
    }
    
    func clockIn(activity: String) async throws {
        let body = try JSONEncoder().encode(["activity": activity])
        let _: TimeEntry = try await APIClient.shared.request("/time/clock-in", method: "POST", body: body)
        loadData()
    }
    
    func clockOut(entryId: String? = nil) async throws {
        var endpoint = "/time/clock-out"
        if let id = entryId {
            endpoint += "?entry_id=\(id)"
        }
        let _: AnyCodable = try await APIClient.shared.request(endpoint, method: "POST")
        loadData()
    }
    
    func updateTaskStatus(taskId: String, status: String) async throws {
        let body = try JSONEncoder().encode(["status": status])
        let _: TaskItem = try await APIClient.shared.request("/tasks/\(taskId)", method: "PATCH", body: body)
        loadData()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.now = Date()
                self.calculateTodayHours()
                
                // For the "SHIFT" display, use the earliest active clock
                if let first = self.activeEntries.first {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let startDate = formatter.date(from: first.clockIn) {
                        self.liveSeconds = Int(self.now.timeIntervalSince(startDate))
                    }
                } else {
                    self.liveSeconds = 0
                }
            }
        }
    }
    
    struct AwardResponse: Codable {
        let items: [Award]
        let earnedCount: Int
        let total: Int
        
        enum CodingKeys: String, CodingKey {
            case items, total
            case earnedCount = "earned_count"
        }
    }
}
