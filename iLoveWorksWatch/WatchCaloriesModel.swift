//
//  WatchCaloriesModel.swift
//  iLoveWorksWatch
//
//  Today's Active + Total calories, plus an optional live workout that updates every
//  few seconds. Numbers go to the iPhone over WatchConnectivity (Bluetooth or Wi-Fi,
//  chosen by the system); the iPhone app sends them to the server.
//

import Foundation
import Combine
import HealthKit
import WatchConnectivity

@MainActor
final class WatchCaloriesModel: ObservableObject {
    @Published var todayActive: Double = 0
    @Published var todayBasal: Double = 0
    @Published var sessionActive: Double = 0
    @Published var isLive = false
    @Published var liveStart: Date?
    @Published var authorized = false
    @Published var phoneReachable = false
    @Published var message: String?

    let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let bridge = WatchBridge()
    private var queriesStarted = false
    private var baseActiveAtStart: Double = 0
    private var lastSent = Date.distantPast

    var displayActive: Double { max(todayActive, isLive ? baseActiveAtStart + sessionActive : 0) }
    var displayTotal: Double { displayActive + todayBasal }

    init() {
        bridge.model = self
    }

    private var energyTypes: Set<HKQuantityType> {
        Set([HKQuantityTypeIdentifier.activeEnergyBurned, .basalEnergyBurned].compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
    }

    func start() async {
        activatePhoneLink()
        guard HKHealthStore.isHealthDataAvailable() else {
            message = "Apple Health isn't available."
            return
        }
        do {
            let share: Set<HKSampleType> = Set(energyTypes).union([HKObjectType.workoutType()])
            try await store.requestAuthorization(toShare: share, read: energyTypes)
            authorized = true
            startTodayQueries()
        } catch {
            message = error.localizedDescription
        }
    }

    private func startTodayQueries() {
        guard !queriesStarted else { return }
        queriesStarted = true
        for id in [HKQuantityTypeIdentifier.activeEnergyBurned, .basalEnergyBurned] {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }
            let isActive = id == .activeEnergyBurned
            let q = Self.todayQuery(type: type) { kcal in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if isActive { self.todayActive = kcal } else { self.todayBasal = kcal }
                    self.sendToPhone(force: false)
                }
            }
            store.execute(q)
        }
    }

    /// Keeps today's running total as Apple Health receives new samples.
    nonisolated private static func todayQuery(type: HKQuantityType, onValue: @escaping @Sendable (Double) -> Void) -> HKStatisticsCollectionQuery {
        let start = Calendar.current.startOfDay(for: Date())
        let q = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: nil, options: []),
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(day: 1)
        )
        let read: @Sendable (HKStatisticsCollection?) -> Void = { collection in
            onValue(collection?.statistics(for: Date())?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
        }
        q.initialResultsHandler = { _, collection, _ in read(collection) }
        q.statisticsUpdateHandler = { _, _, collection, _ in read(collection) }
        return q
    }

    // MARK: Live workout

    func toggleLive() {
        if isLive { stopLive() } else { startLive() }
    }

    private func startLive() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = bridge
            b.delegate = bridge
            session = s
            builder = b
            baseActiveAtStart = todayActive
            sessionActive = 0
            let now = Date()
            s.startActivity(with: now)
            b.beginCollection(withStart: now) { _, _ in }
            isLive = true
            liveStart = now
            message = nil
            sendToPhone(force: true)
        } catch {
            message = error.localizedDescription
        }
    }

    private func stopLive() {
        guard let s = session, let b = builder else { return }
        s.end()
        b.endCollection(withEnd: Date()) { _, _ in
            b.finishWorkout { _, _ in }
        }
        isLive = false
        liveStart = nil
        session = nil
        builder = nil
        sendToPhone(force: true)
    }

    func liveEnergy(_ kcal: Double) {
        sessionActive = kcal
        sendToPhone(force: false)
    }

    // MARK: iPhone link

    func activatePhoneLink() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = bridge
        WCSession.default.activate()
    }

    func sendToPhone(force: Bool) {
        let now = Date()
        guard force || now.timeIntervalSince(lastSent) >= 5 else { return }
        lastSent = now
        let payload: [String: Any] = [
            "active": displayActive,
            "total": displayTotal,
            "live": isLive,
            "day": Self.day(now),
            "at": now.timeIntervalSince1970,
        ]
        let s = WCSession.default
        guard s.activationState == .activated else { return }
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
        try? s.updateApplicationContext(payload)  // delivered later if the phone is away
    }

    static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

/// HealthKit and WatchConnectivity call back on background queues.
final class WatchBridge: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WCSessionDelegate, @unchecked Sendable {
    weak var model: WatchCaloriesModel?

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        let text = error.localizedDescription
        Task { @MainActor [weak self] in self?.model?.message = text }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned), collectedTypes.contains(type) else { return }
        let kcal = workoutBuilder.statistics(for: type)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        Task { @MainActor [weak self] in self?.model?.liveEnergy(kcal) }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let reachable = session.isReachable
        Task { @MainActor [weak self] in
            self?.model?.phoneReachable = reachable
            self?.model?.sendToPhone(force: true)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor [weak self] in self?.model?.phoneReachable = reachable }
    }
}
