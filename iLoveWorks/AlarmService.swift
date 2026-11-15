//
//  AlarmService.swift
//  iLoveWorks
//
//  Alarms ring from the phone's own schedule (UNUserNotificationCenter), so they work with the
//  app closed and need no Apple push setup. The server keeps the list so web and phone agree.
//

import Foundation
import Combine
import UserNotifications

struct AlarmItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let note: String?
    let taskId: String?
    let fireAt: String
    let status: String
    let source: String?
}

private struct NewAlarm: Encodable {
    let title: String
    let fireAt: String
    let note: String?
    let taskId: String?
    let source: String
}

/// A draft shown in the "Set alarm" sheet.
struct AlarmDraft: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var taskId: String?

    /// Defaults to 30 min before the task's due time (today, or tomorrow if passed), else one hour from now.
    init(title: String = "", dueTime: String? = nil, taskId: String? = nil) {
        self.title = title
        self.taskId = taskId
        let now = Date()
        var date = now.addingTimeInterval(3600)
        if let dueTime {
            let parts = dueTime.split(separator: ":").compactMap { Int($0) }
            if parts.count >= 2, var d = Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: now) {
                d = d.addingTimeInterval(-30 * 60)
                if d <= now { d = d.addingTimeInterval(24 * 3600) }
                date = d
            }
        }
        self.date = date
    }
}

enum AlarmScheduler {
    static let category = "ILW_ALARM"
    static let snoozeAction = "ILW_ALARM_SNOOZE"
    static let stopAction = "ILW_ALARM_STOP"
    /// Extra rings 1 and 2 minutes later, until Stop or Snooze is tapped.
    static let followUps = 2

    static func registerCategory() {
        let snooze = UNNotificationAction(identifier: snoozeAction, title: "Snooze 10 min", options: [])
        let stop = UNNotificationAction(identifier: stopAction, title: "Stop", options: [.destructive])
        let cat = UNNotificationCategory(identifier: category, actions: [snooze, stop], intentIdentifiers: [], options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }

    static func ids(for alarmId: String) -> [String] {
        (0...followUps).map { "alarm-\(alarmId)-\($0)" }
    }

    static func schedule(_ alarm: AlarmItem) async {
        guard let fire = APIDate.parse(alarm.fireAt), fire > Date() else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids(for: alarm.id))
        for i in 0...followUps {
            let content = UNMutableNotificationContent()
            content.title = "⏰ \(alarm.title)"
            content.body = i == 0 ? (alarm.note ?? "Your alarm is ringing.") : "Still ringing. Tap Stop or Snooze."
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
            content.categoryIdentifier = category
            content.interruptionLevel = .timeSensitive
            content.threadIdentifier = "alarm-\(alarm.id)"
            content.userInfo = ["alarm_id": alarm.id]
            let when = fire.addingTimeInterval(Double(i) * 60)
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: when)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            do {
                try await center.add(UNNotificationRequest(identifier: "alarm-\(alarm.id)-\(i)", content: content, trigger: trigger))
            } catch {
                print("Alarm schedule failed: \(error)")
            }
        }
    }

    static func cancel(_ alarmId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids(for: alarmId))
        center.removeDeliveredNotifications(withIdentifiers: ids(for: alarmId))
    }
}

final class AlarmStore: ObservableObject {
    static let shared = AlarmStore()

    @Published private(set) var alarms: [AlarmItem] = []
    @Published var lastError: String?

    /// iOS keeps at most 64 pending notifications; each alarm uses 3.
    private let maxScheduled = 20

    private init() {}

    var upcoming: [AlarmItem] { alarms.filter { $0.status == "scheduled" } }

    /// Pull the server list and make the phone's own schedule match it (covers alarms made on the web).
    func sync() async {
        guard APIClient.shared.token != nil else { return }
        do {
            let list: [AlarmItem] = try await APIClient.shared.request("/alarms")
            alarms = list
            lastError = nil
            await reschedule()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func reschedule() async {
        let center = UNUserNotificationCenter.current()
        let keepAlarms = Array(upcoming.prefix(maxScheduled))
        let keep = Set(keepAlarms.flatMap { AlarmScheduler.ids(for: $0.id) })
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map { $0.identifier }.filter { $0.hasPrefix("alarm-") && !keep.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for a in keepAlarms { await AlarmScheduler.schedule(a) }
    }

    func create(title: String, at date: Date, note: String?, taskId: String?) async throws {
        let body = NewAlarm(title: title, fireAt: ISO8601DateFormatter().string(from: date), note: note, taskId: taskId, source: "ios")
        let a: AlarmItem = try await APIClient.shared.send("/alarms", json: body)
        upsert(a)
        await AlarmScheduler.schedule(a)
    }

    func cancel(_ a: AlarmItem) async {
        AlarmScheduler.cancel(a.id)
        alarms.removeAll { $0.id == a.id }
        let _: EmptyResponse? = try? await APIClient.shared.request("/alarms/\(a.id)", method: "DELETE")
    }

    func snooze(id: String, minutes: Int = 10) async {
        AlarmScheduler.cancel(id)
        if let a: AlarmItem = try? await APIClient.shared.send("/alarms/\(id)/snooze", json: ["minutes": minutes]) {
            upsert(a)
            await AlarmScheduler.schedule(a)
        } else {
            // Offline: still ring again on this phone.
            let title = alarms.first { $0.id == id }?.title ?? "Alarm"
            let fire = ISO8601DateFormatter().string(from: Date().addingTimeInterval(Double(minutes) * 60))
            await AlarmScheduler.schedule(AlarmItem(id: id, title: title, note: nil, taskId: nil, fireAt: fire, status: "scheduled", source: "ios"))
        }
    }

    func stop(id: String) async {
        AlarmScheduler.cancel(id)
        let _: EmptyResponse? = try? await APIClient.shared.request("/alarms/\(id)/dismiss", method: "POST")
        await sync()
    }

    /// Signed out: nothing should ring for the previous account.
    func clearLocal() {
        for a in alarms { AlarmScheduler.cancel(a.id) }
        alarms = []
    }

    private func upsert(_ a: AlarmItem) {
        alarms.removeAll { $0.id == a.id }
        alarms.append(a)
        alarms.sort { $0.fireAt < $1.fireAt }
    }
}
