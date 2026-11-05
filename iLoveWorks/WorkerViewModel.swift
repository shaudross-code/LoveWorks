//
//  WorkerViewModel.swift
//  iLoveWorks
//

import SwiftUI
import Combine

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
    @Published var loadError: String?

    @Published var liveSeconds: Int = 0
    @Published var todayHours: Double = 0.0
    @Published var now = Date()

    private var ticker: Task<Void, Never>?

    var deadlines: DeadlineBuckets { TaskSchedule.buckets(tasks, now: now) }

    func loadData() {
        Task { await refresh() }
    }

    func refresh() async {
        let api = APIClient.shared
        async let active: [TimeEntry]? = try? await api.request("/time/active")
        async let fetchedTasks: [TaskItem]? = try? await api.request("/tasks")
        async let fetchedEntries: [TimeEntry]? = try? await api.request("/time/entries")
        async let fetchedGoals: [Goal]? = try? await api.request("/goals?kind=goal")
        async let fetchedTrips: [Goal]? = try? await api.request("/goals?kind=trip")
        async let fetchedEssentials: [Essential]? = try? await api.request("/essentials")
        async let fetchedAnnouncements: [Announcement]? = try? await api.request("/announcements")
        async let fetchedNotifs: NotificationsResponse? = try? await api.request("/notifications")
        async let fetchedActivity: WeeklyActivityResponse? = try? await api.request("/me/weekly-activity")
        async let fetchedAwards: AwardResponse? = try? await api.request("/awards")

        let resTasks = await fetchedTasks
        if let v = await active { activeEntries = v }
        if let v = resTasks { tasks = v }
        if let v = await fetchedEntries { allEntries = v }
        if let v = await fetchedGoals { goals = v }
        if let v = await fetchedTrips { trips = v }
        if let v = await fetchedEssentials { essentials = v }
        if let v = await fetchedAnnouncements { announcements = v }
        if let v = await fetchedNotifs { notifications = v.items; unreadNotificationsCount = v.unread }
        if let v = await fetchedActivity { weeklyActivity = v.completionsByDay; streakDays = v.streakDays }
        if let v = await fetchedAwards { awards = v.items }
        loadError = resTasks == nil ? "Couldn't reach iLoveWorks. Pull down to try again." : nil

        tick()
        startTimer()
    }

    func clockIn(activity: String) async throws {
        let _: TimeEntry = try await APIClient.shared.send("/time/clock-in", json: ["activity": activity])
        await refresh()
    }

    func clockOut(entryId: String? = nil) async throws {
        var endpoint = "/time/clock-out"
        if let id = entryId { endpoint += "?entry_id=\(id)" }
        let _: EmptyResponse = try await APIClient.shared.request(endpoint, method: "POST")
        await refresh()
    }

    func updateTaskStatus(taskId: String, status: String) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\(taskId)", method: "PATCH", json: ["status": status])
        await refresh()
    }

    func setReactions(goalId: String, _ reactions: [GoalReaction]) {
        if let i = goals.firstIndex(where: { $0.id == goalId }) { goals[i].reactions = reactions }
        if let i = trips.firstIndex(where: { $0.id == goalId }) { trips[i].reactions = reactions }
    }

    func markNotificationsRead() {
        guard unreadNotificationsCount > 0 else { return }
        Task {
            let _: EmptyResponse? = try? await APIClient.shared.request("/notifications/read-all", method: "POST")
            unreadNotificationsCount = 0
        }
    }

    /// Seconds clocked today: finished entries that ended today + every running clock.
    private func todaySeconds() -> Int {
        let startOfToday = Calendar.current.startOfDay(for: now)
        var total = 0
        for e in allEntries where e.clockOut != nil {
            if let out = APIDate.parse(e.clockOut), out >= startOfToday { total += e.seconds }
        }
        for e in activeEntries {
            if let inDt = APIDate.parse(e.clockIn) { total += max(0, Int(now.timeIntervalSince(max(inDt, startOfToday)))) }
        }
        return total
    }

    private func tick() {
        now = Date()
        todayHours = Double(todaySeconds()) / 3600
        if let first = activeEntries.first, let start = APIDate.parse(first.clockIn) {
            liveSeconds = max(0, Int(now.timeIntervalSince(start)))
        } else {
            liveSeconds = 0
        }
    }

    private func startTimer() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.tick()
            }
        }
    }
}
