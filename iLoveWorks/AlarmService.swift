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
    var repeatDays: [Int]? = nil
    var timeOfDay: String? = nil
    var tz: String? = nil

    /// 0 = Monday … 6 = Sunday (same as the server).
    var isRepeating: Bool { !(repeatDays ?? []).isEmpty && timeOfDay != nil }

    static let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    static let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    static func repeatSummary(_ days: [Int]) -> String {
        let s = days.sorted()
        if s == [0, 1, 2, 3, 4] { return "Weekdays" }
        if s == [5, 6] { return "Weekends" }
        if s.count == 7 { return "Every day" }
        return s.compactMap { (0...6).contains($0) ? dayNames[$0] : nil }.joined(separator: ", ")
    }
}

private struct NewAlarm: Encodable {
    let title: String
    let fireAt: String?
    let note: String?
    let taskId: String?
    let source: String
    let repeatDays: [Int]?
    let timeOfDay: String?
    let tz: String?
}

/// A draft shown in the "Set alarm" sheet.
struct AlarmDraft: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var taskId: String?
    var repeatDays: [Int] = []

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
        (0...followUps).map { "alarm-\(alarmId)-\($0)" } + (0...6).map { "alarm-\(alarmId)-d\($0)" }
    }

    private static func content(_ alarm: AlarmItem, followUp: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(alarm.title)"
        content.body = followUp ? "Still ringing. Tap Stop or Snooze." : (alarm.note ?? "Your alarm is ringing.")
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
        content.categoryIdentifier = category
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = "alarm-\(alarm.id)"
        content.userInfo = ["alarm_id": alarm.id]
        return content
    }

    private static func add(_ id: String, _ content: UNMutableNotificationContent, _ comps: DateComponents, repeats: Bool) async {
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
        do {
            try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } catch {
            print("Alarm schedule failed: \(error)")
        }
    }

    private static func exact(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    static func schedule(_ alarm: AlarmItem) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids(for: alarm.id))
        if alarm.isRepeating, let days = alarm.repeatDays, let tod = alarm.timeOfDay {
            await scheduleWeekly(alarm, days: days, timeOfDay: tod)
            return
        }
        guard let fire = APIDate.parse(alarm.fireAt), fire > Date() else { return }
        for i in 0...followUps {
            await add("alarm-\(alarm.id)-\(i)", content(alarm, followUp: i > 0), exact(fire.addingTimeInterval(Double(i) * 60)), repeats: false)
        }
    }

    /// One repeating trigger per chosen weekday; iOS keeps ringing them with the app closed.
    private static func scheduleWeekly(_ alarm: AlarmItem, days: [Int], timeOfDay: String) async {
        let parts = timeOfDay.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return }
        for d in days where (0...6).contains(d) {
            var comps = DateComponents()
            comps.weekday = (d + 1) % 7 + 1  // server 0=Mon → Calendar 2; 6=Sun → 1
            comps.hour = parts[0]
            comps.minute = parts[1]
            await add("alarm-\(alarm.id)-d\(d)", content(alarm, followUp: false), comps, repeats: true)
        }
        // Snoozed (next ring isn't on the usual slot): ring once more at the snooze time.
        if let fire = APIDate.parse(alarm.fireAt), fire > Date() {
            let c = Calendar.current.dateComponents([.hour, .minute], from: fire)
            if c.hour != parts[0] || c.minute != parts[1] {
                await add("alarm-\(alarm.id)-0", content(alarm, followUp: false), exact(fire), repeats: false)
            }
        }
    }

    /// Offline snooze: ring once at `date` without touching a repeating schedule.
    static func ringOnce(_ alarm: AlarmItem, at date: Date) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm-\(alarm.id)-0"])
        await add("alarm-\(alarm.id)-0", content(alarm, followUp: false), exact(date), repeats: false)
    }

    /// Clear what's on screen; a repeating alarm keeps its future rings.
    static func stopRinging(_ alarm: AlarmItem?, id alarmId: String) {
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: ids(for: alarmId))
        if alarm?.isRepeating == true {
            center.removePendingNotificationRequests(withIdentifiers: (0...followUps).map { "alarm-\(alarmId)-\($0)" })
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ids(for: alarmId))
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

    /// iOS keeps at most 64 pending notifications; budget them across alarms.
    private let maxPending = 60

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
        var budget = maxPending
        var keepAlarms: [AlarmItem] = []
        for a in upcoming {
            let cost = a.isRepeating ? (a.repeatDays?.count ?? 0) + 1 : AlarmScheduler.followUps + 1
            guard cost <= budget else { break }
            budget -= cost
            keepAlarms.append(a)
        }
        let keep = Set(keepAlarms.flatMap { AlarmScheduler.ids(for: $0.id) })
        let pending = await center.pendingNotificationRequests()
        let stale = pending.map { $0.identifier }.filter { $0.hasPrefix("alarm-") && !keep.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for a in keepAlarms { await AlarmScheduler.schedule(a) }
    }

    func create(title: String, at date: Date, note: String?, taskId: String?, repeatDays: [Int] = []) async throws {
        let repeating = !repeatDays.isEmpty
        let hm = Calendar.current.dateComponents([.hour, .minute], from: date)
        let body = NewAlarm(
            title: title,
            fireAt: repeating ? nil : ISO8601DateFormatter().string(from: date),
            note: note, taskId: taskId, source: "ios",
            repeatDays: repeating ? repeatDays.sorted() : nil,
            timeOfDay: repeating ? String(format: "%02d:%02d", hm.hour ?? 0, hm.minute ?? 0) : nil,
            tz: repeating ? TimeZone.current.identifier : nil
        )
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
        let existing = alarms.first { $0.id == id }
        AlarmScheduler.stopRinging(existing, id: id)
        if let a: AlarmItem = try? await APIClient.shared.send("/alarms/\(id)/snooze", json: ["minutes": minutes]) {
            upsert(a)
            await AlarmScheduler.schedule(a)
        } else {
            // Offline: still ring again on this phone.
            let fallback = existing ?? AlarmItem(id: id, title: "Alarm", note: nil, taskId: nil, fireAt: "", status: "scheduled", source: "ios")
            await AlarmScheduler.ringOnce(fallback, at: Date().addingTimeInterval(Double(minutes) * 60))
        }
    }

    func stop(id: String) async {
        AlarmScheduler.stopRinging(alarms.first { $0.id == id }, id: id)
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
