//
//  HealthSync.swift
//  iLoveWorks
//
//  Reads today's Active + Total calories (Apple Watch) and the latest weigh-in
//  (VeSync/Etekcity scale via Apple Health or straight over Bluetooth) and sends them to the server.
//  Total = Active + Resting energy, the same as the Fitness app.
//

#if os(iOS) && canImport(HealthKit)
import Foundation
import Combine
import HealthKit

/// HealthKit calls run off the main actor; results hop back to HealthSync.
nonisolated struct HealthReader {
    let store: HKHealthStore

    static let readIds: [HKQuantityTypeIdentifier] = [.activeEnergyBurned, .basalEnergyBurned, .bodyMass, .bodyFatPercentage, .bodyMassIndex]

    var readTypes: Set<HKObjectType> {
        Set(Self.readIds.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
    }

    func sumToday(_ id: HKQuantityTypeIdentifier) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: .kilocalorie()))
            }
            store.execute(q)
        }
    }

    func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> (value: Double, date: Date)? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                if let s = samples?.first as? HKQuantitySample {
                    cont.resume(returning: (s.quantity.doubleValue(for: unit), s.endDate))
                } else {
                    cont.resume(returning: nil)
                }
            }
            store.execute(q)
        }
    }

    func saveWeight(kg: Double, at date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        try await store.requestAuthorization(toShare: [type], read: readTypes)
        let sample = HKQuantitySample(type: type, quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg), start: date, end: date)
        try await store.save(sample)
    }

    /// Wake the app (about hourly) when new calories or a weigh-in land in Apple Health.
    func observe(onChange: @escaping @Sendable () async -> Void) {
        for id in [HKQuantityTypeIdentifier.activeEnergyBurned, .bodyMass] {
            guard let type = HKQuantityType.quantityType(forIdentifier: id) else { continue }
            let q = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, _ in
                Task {
                    await onChange()
                    completion()
                }
            }
            store.execute(q)
            store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
        }
    }
}

private struct HealthDayUpload: Encodable {
    let date: String
    let activeKcal: Double
    let totalKcal: Double
    let weightKg: Double?
    let bodyFatPct: Double?
    let bmi: Double?
    let weightMeasuredAt: String?
    let weightSource: String?
    let source: String
}

final class HealthSync: ObservableObject {
    static let shared = HealthSync()

    @Published private(set) var activeKcal: Double?
    @Published private(set) var totalKcal: Double?
    @Published private(set) var weightKg: Double?
    @Published private(set) var bodyFatPct: Double?
    @Published private(set) var bmi: Double?
    @Published private(set) var weightDate: Date?
    @Published private(set) var weightSource: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var liveFromWatch = false
    @Published private(set) var connected = UserDefaults.standard.bool(forKey: "ilw.health.connected")
    @Published var shareWithAdmin = false
    @Published var lastError: String?

    private let store = HKHealthStore()
    private lazy var reader = HealthReader(store: store)
    private var observing = false
    private var lastUpload = Date.distantPast
    private var liveDay = ""
    private var liveActive: Double = 0
    private var liveTotal: Double = 0

    private init() {
        let d = UserDefaults.standard
        if d.double(forKey: "ilw.scale.lastKg") > 0, let at = d.object(forKey: "ilw.scale.lastAt") as? Date {
            weightKg = d.double(forKey: "ilw.scale.lastKg")
            weightDate = at
            weightSource = "scale_bluetooth"
        }
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Ask for Apple Health access (shows Apple's permission sheet the first time).
    func connect() async {
        guard isAvailable else {
            lastError = "Apple Health isn't available on this device."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: reader.readTypes)
            UserDefaults.standard.set(true, forKey: "ilw.health.connected")
            connected = true
            lastError = nil
            start()
            await refresh(upload: true)
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Called on sign-in and app launch.
    func start() {
        guard connected, isAvailable, !observing else { return }
        observing = true
        reader.observe { await HealthSync.shared.refresh(upload: true) }
        Task { await loadSharing() }
    }

    func refresh(upload: Bool) async {
        guard connected, isAvailable else { return }
        let active = await reader.sumToday(.activeEnergyBurned) ?? 0
        let basal = await reader.sumToday(.basalEnergyBurned) ?? 0
        let today = Self.day(Date())
        let liveA = liveDay == today ? liveActive : 0
        let liveT = liveDay == today ? liveTotal : 0
        activeKcal = max(active, liveA)
        totalKcal = max(active + basal, liveT, activeKcal ?? 0)
        // A Bluetooth weigh-in stays until Apple Health has a newer one.
        if let w = await reader.latest(.bodyMass, unit: .gramUnit(with: .kilo)), w.date > (weightDate ?? .distantPast) {
            weightKg = w.value
            weightDate = w.date
            weightSource = "apple_health"
            if let f = await reader.latest(.bodyFatPercentage, unit: .percent()) { bodyFatPct = f.value * 100 }
            if let b = await reader.latest(.bodyMassIndex, unit: .count()) { bmi = b.value }
        }
        lastUpdated = Date()
        if upload { await send(force: true) }
    }

    /// Live numbers from the iLoveWorks Watch app (seconds old).
    func applyLive(active: Double, total: Double, day: String, live: Bool) {
        guard day == Self.day(Date()) else { return }
        liveDay = day
        liveActive = active
        liveTotal = total
        liveFromWatch = live
        activeKcal = max(activeKcal ?? 0, active)
        totalKcal = max(totalKcal ?? 0, total, activeKcal ?? 0)
        lastUpdated = Date()
        Task { await send(force: false) }
    }

    /// A weigh-in read straight from the scale over Bluetooth, saved after the worker taps Save.
    func applyScale(kg: Double, at date: Date, saveToHealth: Bool) async {
        weightKg = kg
        weightDate = date
        weightSource = "scale_bluetooth"
        bodyFatPct = nil
        bmi = nil
        UserDefaults.standard.set(kg, forKey: "ilw.scale.lastKg")
        UserDefaults.standard.set(date, forKey: "ilw.scale.lastAt")
        lastUpdated = Date()
        if saveToHealth {
            do { try await reader.saveWeight(kg: kg, at: date) } catch { lastError = error.localizedDescription }
        }
        await send(force: true)
    }

    /// Another worker may sign in on this phone next; don't carry this one's weigh-in over.
    func signedOut() {
        UserDefaults.standard.removeObject(forKey: "ilw.scale.lastKg")
        UserDefaults.standard.removeObject(forKey: "ilw.scale.lastAt")
        weightKg = nil
        weightDate = nil
        weightSource = nil
        bodyFatPct = nil
        bmi = nil
        shareWithAdmin = false
    }

    private func send(force: Bool) async {
        guard APIClient.shared.token != nil, activeKcal != nil || weightKg != nil else { return }
        let active = activeKcal ?? 0
        // Live updates arrive every few seconds; the server only needs one a minute.
        guard force || Date().timeIntervalSince(lastUpload) > 60 else { return }
        lastUpload = Date()
        let body = HealthDayUpload(
            date: Self.day(Date()),
            activeKcal: active,
            totalKcal: totalKcal ?? active,
            weightKg: weightKg,
            bodyFatPct: bodyFatPct.map { min(max($0, 1), 80) },
            bmi: bmi,
            weightMeasuredAt: weightDate.map { ISO8601DateFormatter().string(from: $0) },
            weightSource: weightKg == nil ? nil : weightSource ?? "apple_health",
            source: liveFromWatch ? "watch_live" : "apple_health"
        )
        do {
            let _: EmptyResponse = try await APIClient.shared.send("/health/daily", json: body)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private struct HealthMe: Decodable { let shareWithAdmin: Bool }

    func loadSharing() async {
        if let me: HealthMe = try? await APIClient.shared.request("/health/me?days=1") { shareWithAdmin = me.shareWithAdmin }
    }

    func setSharing(_ on: Bool) async {
        shareWithAdmin = on
        let _: EmptyResponse? = try? await APIClient.shared.send("/health/sharing", method: "PATCH", json: ["share": on])
    }

    static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
#endif
