//
//  AdminViewModel.swift
//  iLoveWorks
//

import SwiftUI
import Combine

struct WorkerStatus: Codable, Identifiable {
    let worker: User
    let online: Bool
    let lastSeenAt: String?
    let currentlyClockedIn: Bool
    let activeActivity: String?
    let todayWorkedHours: Double
    let weekWorkedHours: Double
    let dailyRequiredHours: Double
    let weeklyRequiredHours: Double
    let todayLeftHours: Double
    let weekLeftHours: Double
    let potentialWeekly: Double
    let potentialMonthly: Double
    let openTasksCount: Int
    let streakDays: Int
    let inconsistencies: Inconsistencies
    
    var id: String { worker.id }
    
    struct Inconsistencies: Codable {
        let missedDays: [Int]
        let lowDays: [Int]
        let streakBroken: Bool
        let totalIssues: Int
        
        enum CodingKeys: String, CodingKey {
            case missedDays = "missed_days", lowDays = "low_days", streakBroken = "streak_broken", totalIssues = "total_issues"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case worker, online, currentlyClockedIn = "currently_clocked_in", potentialWeekly = "potential_weekly", potentialMonthly = "potential_monthly", openTasksCount = "open_tasks_count", streakDays = "streak_days", inconsistencies
        case lastSeenAt = "last_seen_at"
        case activeActivity = "active_activity"
        case todayWorkedHours = "today_worked_hours"
        case weekWorkedHours = "week_worked_hours"
        case dailyRequiredHours = "daily_required_hours"
        case weeklyRequiredHours = "weekly_required_hours"
        case todayLeftHours = "today_left_hours"
        case weekLeftHours = "week_left_hours"
    }
}

struct PayrollRow: Codable, Identifiable {
    let worker: User
    let tasksCompleted: Int
    let tasksEarnings: Double
    let totalHours: Double
    
    var id: String { worker.id }
    
    enum CodingKeys: String, CodingKey {
        case worker, tasksCompleted = "tasks_completed", tasksEarnings = "tasks_earnings", totalHours = "total_hours"
    }
}

class AdminViewModel: ObservableObject {
    @Published var workerStatuses: [WorkerStatus] = []
    @Published var payroll: [PayrollRow] = []
    @Published var workers: [User] = []
    @Published var goals: [Goal] = []
    @Published var trips: [Goal] = []
    @Published var essentials: [Essential] = []
    @Published var announcements: [Announcement] = []
    @Published var tasks: [TaskItem] = []
    
    // Stats for Dashboard
    @Published var statsWorkersCount = 0
    @Published var statsActiveCount = 0
    @Published var statsHoursLogged = 0.0
    @Published var statsTasksAssigned = 0
    @Published var statsCompletedCount = 0
    @Published var statsTotalPayroll = 0.0
    
    func loadDashboard() {
        Task {
            do {
                async let w: [User] = try await APIClient.shared.request("/workers")
                async let t: [TaskItem] = try await APIClient.shared.request("/tasks")
                async let p: [PayrollRow] = try await APIClient.shared.request("/payroll")
                async let ws: [WorkerStatus] = try await APIClient.shared.request("/admin/worker-status")
                
                let resWorkers = try await w
                let resTasks = try await t
                let resPayroll = try await p
                let resStatuses = try await ws
                
                await MainActor.run {
                    self.workers = resWorkers
                    self.tasks = resTasks
                    self.payroll = resPayroll
                    self.workerStatuses = resStatuses
                    
                    self.statsWorkersCount = resWorkers.count
                    self.statsActiveCount = resStatuses.filter { $0.currentlyClockedIn }.count
                    self.statsHoursLogged = resPayroll.reduce(0) { $0 + $1.totalHours }
                    self.statsTasksAssigned = resTasks.count
                    self.statsCompletedCount = resTasks.filter { $0.status == "completed" }.count
                    self.statsTotalPayroll = resPayroll.reduce(0) { $0 + $1.tasksEarnings }
                }
            } catch {
                print("Failed to load admin dashboard: \(error)")
            }
        }
    }
    
    func loadGoals() {
        Task {
            do {
                let allGoals: [Goal] = try await APIClient.shared.request("/goals?kind=goal")
                await MainActor.run {
                    self.goals = allGoals
                }
            } catch {
                print("Failed to load goals: \(error)")
            }
        }
    }
    
    func loadTrips() {
        Task {
            do {
                let allTrips: [Goal] = try await APIClient.shared.request("/goals?kind=trip")
                await MainActor.run {
                    self.trips = allTrips
                }
            } catch {
                print("Failed to load trips: \(error)")
            }
        }
    }
    
    func loadEssentials() {
        Task {
            do {
                let allEssentials: [Essential] = try await APIClient.shared.request("/essentials")
                await MainActor.run {
                    self.essentials = allEssentials
                }
            } catch {
                print("Failed to load essentials: \(error)")
            }
        }
    }
    
    func loadAnnouncements() {
        Task {
            do {
                let items: [Announcement] = try await APIClient.shared.request("/announcements")
                await MainActor.run {
                    self.announcements = items
                }
            } catch {
                print("Failed to load announcements: \(error)")
            }
        }
    }
    
    func createAnnouncement(title: String, body: String, tag: String = "announcement") async throws {
        let requestBody = try JSONEncoder().encode(AnnouncementCreateRequest(title: title, body: body, tag: tag))
        let _: Announcement = try await APIClient.shared.request("/announcements", method: "POST", body: requestBody)
        loadAnnouncements()
    }
    
    func createGoal(title: String, targetAmount: Double, period: String, ownerId: String, kind: String = "goal") async throws {
        let endpoint = "/goals?title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&target_amount=\(targetAmount)&period=\(period)&assignee_id=\(ownerId)&kind=\(kind)"
        let _: Goal = try await APIClient.shared.request(endpoint, method: "POST")
        if kind == "goal" { loadGoals() } else { loadTrips() }
    }
    
    func createEssential(title: String, price: Double, quantity: Int, category: String, ownerId: String) async throws {
        let endpoint = "/essentials?title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&price=\(price)&quantity=\(quantity)&category=\(category)&assignee_id=\(ownerId)"
        let _: Essential = try await APIClient.shared.request(endpoint, method: "POST")
        loadEssentials()
    }
    
    func createWorker(name: String, email: String, password: String) async throws {
        let body = try JSONEncoder().encode(WorkerCreateRequest(name: name, email: email, password: password))
        let _: User = try await APIClient.shared.request("/workers", method: "POST", body: body)
        loadDashboard()
    }
    
    func createTask(title: String, description: String, price: Double, assigneeId: String) async throws {
        let body = try JSONEncoder().encode(TaskCreateRequest(title: title, description: description, price: price, assigneeId: assigneeId))
        let _: TaskItem = try await APIClient.shared.request("/tasks", method: "POST", body: body)
        loadDashboard()
    }
    
    struct WorkerCreateRequest: Codable {
        let name: String
        let email: String
        let password: String
    }
    
    struct TaskCreateRequest: Codable {
        let title: String
        let description: String
        let price: Double
        let assigneeId: String
        
        enum CodingKeys: String, CodingKey {
            case title, description, price, assigneeId = "assignee_id"
        }
    }
    
    struct AnnouncementCreateRequest: Codable {
        let title: String
        let body: String
        let tag: String
    }
    
    struct GoalCreateRequest: Codable {
        let title: String
        let targetAmount: Double
        let period: String
        let ownerId: String
        
        enum CodingKeys: String, CodingKey {
            case title
            case targetAmount = "target_amount"
            case period
            case ownerId = "owner_id"
        }
    }
}
