//
//  WatchLink.swift
//  iLoveWorks
//
//  Receives live calories from the iLoveWorks Apple Watch app. iPhone and Watch
//  choose Bluetooth or Wi-Fi by themselves; WatchConnectivity handles both.
//

#if os(iOS) && canImport(WatchConnectivity)
import Foundation
import Combine
import WatchConnectivity

nonisolated final class WatchLinkDelegate: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        Task { @MainActor in WatchLink.shared.update(paired: paired, installed: installed, reachable: reachable) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()  // switched to another Watch
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in WatchLink.shared.reachable = reachable }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let reachable = session.isReachable
        Task { @MainActor in WatchLink.shared.update(paired: paired, installed: installed, reachable: reachable) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) { handle(message) }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) { handle(applicationContext) }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) { handle(userInfo) }

    private func handle(_ payload: [String: Any]) {
        guard let active = payload["active"] as? Double, let total = payload["total"] as? Double,
              let day = payload["day"] as? String else { return }
        let live = payload["live"] as? Bool ?? false
        Task { @MainActor in
            WatchLink.shared.lastMessageAt = Date()
            HealthSync.shared.applyLive(active: active, total: total, day: day, live: live)
        }
    }
}

final class WatchLink: ObservableObject {
    static let shared = WatchLink()

    @Published private(set) var supported = WCSession.isSupported()
    @Published private(set) var paired = false
    @Published private(set) var watchAppInstalled = false
    @Published var reachable = false
    @Published var lastMessageAt: Date?

    private let delegate = WatchLinkDelegate()
    private var activated = false

    private init() {}

    func activate() {
        guard supported, !activated else { return }
        activated = true
        WCSession.default.delegate = delegate
        WCSession.default.activate()
    }

    func update(paired: Bool, installed: Bool, reachable: Bool) {
        self.paired = paired
        watchAppInstalled = installed
        self.reachable = reachable
    }
}
#endif
