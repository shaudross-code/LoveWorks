//
//  HealthView.swift
//  iLoveWorks
//
//  "Apple Watch & Health" screen + the compact card on the worker dashboard.
//

import SwiftUI

#if os(iOS) && canImport(HealthKit) && canImport(WatchConnectivity)
struct HealthView: View {
    @ObservedObject private var health = HealthSync.shared
    @ObservedObject private var watch = WatchLink.shared
    @State private var weighing = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PageHeader(eyebrow: "FITNESS", title: "Watch & Scale")
                    HealthNumbersCard()
                        .padding(.horizontal)

                    VStack(spacing: 10) {
                        StatusRow(label: "Apple Health", ok: health.connected, value: health.connected ? "Connected" : "Not connected")
                        StatusRow(label: "Apple Watch paired", ok: watch.paired, value: watch.paired ? "Yes" : "No")
                        StatusRow(label: "iLoveWorks on Watch", ok: watch.watchAppInstalled, value: watch.watchAppInstalled ? "Installed" : "Not installed")
                        StatusRow(label: "Live link", ok: watch.reachable ? true : nil, value: watch.reachable ? "Connected" : "Open iLoveWorks on the Watch")
                    }
                    .padding(.horizontal)

                    if !health.connected {
                        Button(action: { Task { await health.connect() } }) {
                            Label("Connect Apple Health", systemImage: "heart.text.square.fill")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.primary)
                                .foregroundStyle(.black)
                                .cornerRadius(100)
                        }
                        .padding(.horizontal)
                    }

                    ScaleCard(onWeighIn: { weighing = true })
                        .padding(.horizontal)

                    Toggle(isOn: Binding(get: { health.shareWithAdmin }, set: { on in Task { await health.setSharing(on) } })) {
                        Text("Share my calories and weight with my admin")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMain)
                    }
                    .tint(Theme.primary)
                    .padding(.horizontal)

                    if let err = health.lastError {
                        Text(err).font(.system(size: 13)).foregroundStyle(Theme.danger).padding(.horizontal)
                    }

                    GuideSteps()
                        .padding(.horizontal)
                    Spacer(minLength: 40)
                }
            }
            .refreshable { await health.refresh(upload: true) }
        }
        .navigationTitle("Watch & Scale")
        .inlineNavigationTitle()
        .sheet(isPresented: $weighing) { ScaleWeighInView() }
        .task {
            watch.activate()
            health.start()
            await health.loadSharing()
            await health.refresh(upload: true)
        }
    }
}

struct HealthNumbersCard: View {
    @ObservedObject private var health = HealthSync.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Number(label: "ACTIVE", value: health.activeKcal, unit: "kcal", color: Theme.lovePink)
                Number(label: "TOTAL", value: health.totalKcal, unit: "kcal", color: Theme.textMain)
                if let kg = health.weightKg {
                    Number(label: "WEIGHT", value: kg * 2.20462, unit: "lb", color: .cyan, decimals: 1)
                }
            }
            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }

    private var caption: String {
        guard let t = health.lastUpdated else { return "Connect Apple Health to see today's calories." }
        let src = health.liveFromWatch ? "Live from Apple Watch" : "From Apple Health"
        let scale = health.weightSource == "scale_bluetooth" ? " · weight from your scale" : ""
        return "\(src)\(scale) · updated \(t.formatted(date: .omitted, time: .shortened))"
    }

    private struct Number: View {
        let label: String
        let value: Double?
        let unit: String
        let color: Color
        var decimals = 0

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 10, weight: .black)).foregroundStyle(Theme.textMuted).tracking(1.2)
                Text(value.map { String(format: "%.\(decimals)f", $0) } ?? "—")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(unit).font(.system(size: 11)).foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ScaleCard: View {
    @ObservedObject private var scale = ScaleBluetooth.shared
    let onWeighIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Smart scale", systemImage: "scalemass.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textMain)
                Spacer()
                if let name = scale.savedName {
                    Button("Forget") { scale.forget() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .accessibilityIdentifier("scale-forget")
                        .accessibilityLabel("Forget \(name)")
                }
            }
            Text(scale.savedName.map { "Paired: \($0)" } ?? "Read your VeSync (Etekcity) scale over Bluetooth. iPhone asks for Bluetooth permission the first time.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
            Button(action: onWeighIn) {
                Label("Weigh in with Bluetooth", systemImage: "dot.radiowaves.left.and.right")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.primary)
                    .foregroundStyle(.black)
                    .cornerRadius(100)
            }
            .accessibilityIdentifier("scale-weigh-in")
            Text("Works with Etekcity ESF-551, ESF-24 and FIT-8S. Other VeSync scales: use the Apple Health step below.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
}

private struct StatusRow: View {
    let label: String
    let ok: Bool?
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(Theme.textMuted)
            Spacer()
            Label(value, systemImage: ok == true ? "checkmark.circle.fill" : ok == false ? "xmark.circle.fill" : "circle.dashed")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ok == true ? Theme.success : ok == false ? Theme.danger : Theme.textMuted)
        }
        .padding(14)
        .background(Theme.surface)
        .cornerRadius(12)
    }
}

private struct GuideSteps: View {
    private let steps = [
        "Keep Bluetooth and Wi-Fi on. iPhone and Watch pick the link themselves.",
        "iPhone Watch app → My Watch → Available Apps → Install iLoveWorks.",
        "Here, tap Connect Apple Health and allow Active Energy, Resting Energy, Weight, Body Fat and BMI.",
        "Open iLoveWorks on the Watch, allow Health, then tap Start live to record second by second.",
        "Bluetooth scale: tap Weigh in with Bluetooth, allow Bluetooth, close the VeSync app, then step on the scale.",
        "Other VeSync scales: VeSync app → Me → Third-party services → Apple Health → Connect. Weigh-ins then show here.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW TO CONNECT").font(.system(size: 10, weight: .black)).foregroundStyle(Theme.lovePink).tracking(1.5)
            ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)").font(.system(size: 12, weight: .bold)).foregroundStyle(.black)
                        .frame(width: 22, height: 22).background(Theme.primary).clipShape(Circle())
                    Text(s).font(.system(size: 13)).foregroundStyle(Theme.textMain)
                }
            }
        }
    }
}
#endif
