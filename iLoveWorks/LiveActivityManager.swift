//
//  LiveActivityManager.swift
//  iLoveWorks
//
//  Keeps the lock-screen clock-in timer in step with the worker's running clocks.
//  The app starts it locally on clock-in; for clock-ins from the website the server
//  starts it by push, using the push-to-start token this file reports.
//

#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

final class LiveActivityManager {
    static let shared = LiveActivityManager()

    var workerName = ""
    private var observing = false
    private var observed = Set<String>()
    private var pendingStartToken: String?

    private init() {}

    /// Show exactly one timer for the earliest running clock, or none when clocked out.
    func sync(active: [TimeEntry]) async {
        let running = Activity<ClockInAttributes>.activities
        guard let lead = active.first, let start = APIDate.parse(lead.clockIn) else {
            for a in running { await a.end(nil, dismissalPolicy: .immediate) }
            return
        }
        let onBreak = active.contains { $0.activity == "break" }
        let label = ActivityInfo.info(for: onBreak ? "break" : lead.activity).label
        let state = ClockInAttributes.ContentState(onBreak: onBreak, activityLabel: label)

        if let match = running.first(where: { $0.attributes.entryId == lead.id }) {
            if match.content.state != state {
                await match.update(ActivityContent(state: state, staleDate: nil))
            }
            for a in running where a.id != match.id { await a.end(nil, dismissalPolicy: .immediate) }
            return
        }
        for a in running { await a.end(nil, dismissalPolicy: .immediate) }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = ClockInAttributes(entryId: lead.id, workerName: workerName, startedAt: start.timeIntervalSince1970)
        do {
            let activity = try Activity.request(attributes: attrs, content: ActivityContent(state: state, staleDate: nil), pushType: .token)
            observe(activity)
        } catch {
            print("Lock-screen timer failed to start: \(error)")
        }
    }

    func endAll() async {
        for a in Activity<ClockInAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) }
    }

    /// Report tokens so the server can start, update and end the timer for website clock-ins.
    func startObserving() {
        guard !observing else { return }
        observing = true
        Task {
            for await data in Activity<ClockInAttributes>.pushToStartTokenUpdates {
                pendingStartToken = Self.hex(data)
                await flush()
            }
        }
        Task {
            for await activity in Activity<ClockInAttributes>.activityUpdates {
                observe(activity)
            }
        }
        for a in Activity<ClockInAttributes>.activities { observe(a) }
    }

    /// Called again once the Firebase token arrives.
    func flush() async {
        guard let start = pendingStartToken, let fcm = PushManager.shared.token, APIClient.shared.token != nil else { return }
        let ok: EmptyResponse? = try? await APIClient.shared.send("/push/live-activity", json: ["fcm_token": fcm, "start_token": start])
        if ok != nil { pendingStartToken = nil }
    }

    private func observe(_ activity: Activity<ClockInAttributes>) {
        guard !observed.contains(activity.id) else { return }
        observed.insert(activity.id)
        let entryId = activity.attributes.entryId
        Task {
            for await data in activity.pushTokenUpdates {
                guard let fcm = PushManager.shared.token else { continue }
                let _: EmptyResponse? = try? await APIClient.shared.send(
                    "/push/live-activity",
                    json: ["fcm_token": fcm, "activity_token": Self.hex(data), "entry_id": entryId]
                )
            }
        }
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
#endif
