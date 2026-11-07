//
//  AdminViewModel.swift
//  iLoveWorks
//

import SwiftUI
import Combine

class AdminViewModel: ObservableObject {
    @Published var workerStatuses: [WorkerStatus] = []
    @Published var payroll: [PayrollRow] = []
    @Published var workers: [User] = []
    @Published var goals: [Goal] = []
    @Published var trips: [Goal] = []
    @Published var essentials: [Essential] = []
    @Published var announcements: [Announcement] = []
    @Published var tasks: [TaskItem] = []
    @Published var loadError: String?

    // Stats for Dashboard
    @Published var statsWorkersCount = 0
    @Published var statsActiveCount = 0
    @Published var statsHoursLogged = 0.0
    @Published var statsTasksAssigned = 0
    @Published var statsCompletedCount = 0
    @Published var statsTotalPayroll = 0.0

    func loadDashboard() {
        Task { await refreshDashboard() }
    }

    func refreshDashboard() async {
        let api = APIClient.shared
        async let w: [User]? = try? await api.request("/workers")
        async let t: [TaskItem]? = try? await api.request("/tasks")
        async let p: [PayrollRow]? = try? await api.request("/payroll")
        async let ws: [WorkerStatus]? = try? await api.request("/admin/worker-status")

        let resWorkers = await w
        if let v = resWorkers { workers = v; statsWorkersCount = v.count }
        if let v = await t {
            tasks = v
            statsTasksAssigned = v.count
            statsCompletedCount = v.filter { $0.isCompleted }.count
        }
        if let v = await p {
            payroll = v
            statsHoursLogged = v.reduce(0) { $0 + $1.totalHours }
            statsTotalPayroll = v.reduce(0) { $0 + $1.tasksEarnings }
        }
        if let v = await ws {
            workerStatuses = v
            statsActiveCount = v.filter { $0.currentlyClockedIn }.count
        }
        loadError = resWorkers == nil ? "Couldn't reach iLoveWorks. Pull down to try again." : nil
    }

    func loadGoals() {
        Task { if let v: [Goal] = try? await APIClient.shared.request("/goals?kind=goal") { goals = v } }
    }

    func loadTrips() {
        Task { if let v: [Goal] = try? await APIClient.shared.request("/goals?kind=trip") { trips = v } }
    }

    func loadEssentials() {
        Task { if let v: [Essential] = try? await APIClient.shared.request("/essentials") { essentials = v } }
    }

    func loadAnnouncements() {
        Task { if let v: [Announcement] = try? await APIClient.shared.request("/announcements") { announcements = v } }
    }

    func setReactions(goalId: String, _ reactions: [GoalReaction]) {
        if let i = goals.firstIndex(where: { $0.id == goalId }) { goals[i].reactions = reactions }
        if let i = trips.firstIndex(where: { $0.id == goalId }) { trips[i].reactions = reactions }
    }

    func createAnnouncement(title: String, body: String, tag: String = "announcement") async throws {
        let _: Announcement = try await APIClient.shared.send("/announcements", json: ["title": title, "body": body, "tag": tag])
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
        let _: User = try await APIClient.shared.send("/workers", json: ["name": name, "email": email, "password": password])
        await refreshDashboard()
    }

    func createTask(_ req: TaskCreateRequest) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks", json: req)
        await refreshDashboard()
    }

    struct TaskCreateRequest: Encodable {
        let title: String
        let description: String
        let price: Double
        let assigneeId: String
        let frequency: String
        let dueDayOfWeek: Int?
        let dueTime: String?
        let adminAlarm: String?

        // Send explicit nulls so "no specific day" clears the weekday
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(title, forKey: .title)
            try c.encode(description, forKey: .description)
            try c.encode(price, forKey: .price)
            try c.encode(assigneeId, forKey: .assigneeId)
            try c.encode(frequency, forKey: .frequency)
            try c.encode(dueDayOfWeek, forKey: .dueDayOfWeek)
            try c.encode(dueTime, forKey: .dueTime)
            try c.encode(adminAlarm, forKey: .adminAlarm)
        }

        enum CodingKeys: String, CodingKey {
            case title, description, price, assigneeId, frequency, dueDayOfWeek, dueTime, adminAlarm
        }
    }
}
