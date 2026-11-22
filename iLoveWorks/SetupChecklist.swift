//
//  SetupChecklist.swift
//  iLoveWorks
//
//  "Finish setting up" prompt + dashboard card: alerts, Bluetooth (scale), Apple Health and the Watch app.
//  Every step asks iOS for permission only when the worker taps it.
//

#if os(iOS) && canImport(HealthKit) && canImport(WatchConnectivity) && canImport(CoreBluetooth)
import SwiftUI
import UIKit
import CoreBluetooth

struct SetupStep: Identifiable {
    enum Kind: String { case alerts, bluetooth, health, watch }
    let kind: Kind
    let done: Bool
    let icon: String
    let title: String
    let detail: String
    let action: String
    var id: String { kind.rawValue }
}

enum SetupSteps {
    /// Bump when a new feature needs workers to turn something on; the prompt shows again once.
    static let version = "2026-11-watch-scale"

    static func list() -> [SetupStep] {
        let push = PushManager.shared.status
        let bt = ScaleBluetooth.shared.authorization
        let health = HealthSync.shared
        let watch = WatchLink.shared
        var out = [
            SetupStep(kind: .alerts, done: [.authorized, .provisional, .ephemeral].contains(push), icon: "bell.badge.fill",
                      title: "Alerts",
                      detail: push == .denied ? "Alerts are off for iLoveWorks. Turn them on in Settings to hear about new features, alarms and tasks."
                                              : "Get alerts for new features, alarms, task reminders and announcements.",
                      action: push == .denied ? "Settings" : "Turn on"),
            SetupStep(kind: .bluetooth, done: bt == .allowedAlways, icon: "dot.radiowaves.left.and.right",
                      title: "Bluetooth for your scale",
                      detail: bt == .denied || bt == .restricted ? "Bluetooth is off for iLoveWorks. Turn it on in Settings to read your smart scale."
                                                                 : "Lets iLoveWorks read weigh-ins from your VeSync (Etekcity) scale.",
                      action: bt == .denied || bt == .restricted ? "Settings" : "Allow"),
        ]
        if health.isAvailable {
            out.append(SetupStep(kind: .health, done: health.connected, icon: "heart.text.square.fill", title: "Apple Health",
                                 detail: "Brings in today's calories from your Apple Watch and weigh-ins from your scale.", action: "Connect"))
        }
        if watch.supported {
            out.append(SetupStep(kind: .watch, done: watch.paired && watch.watchAppInstalled, icon: "applewatch",
                                 title: "Apple Watch app",
                                 detail: watch.paired ? "Open the Watch app → Available Apps → Install iLoveWorks."
                                                      : "Have an Apple Watch? Pair it in the Watch app, then install iLoveWorks on it.",
                                 action: "Watch app"))
        }
        return out
    }

    @MainActor
    static func run(_ kind: SetupStep.Kind, openURL: OpenURLAction) async {
        let settings = URL(string: UIApplication.openSettingsURLString)!
        switch kind {
        case .alerts:
            if PushManager.shared.status == .denied { openURL(settings) } else { _ = await PushManager.shared.enable() }
        case .bluetooth:
            let bt = ScaleBluetooth.shared.authorization
            if bt == .denied || bt == .restricted { openURL(settings) } else { ScaleBluetooth.shared.requestPermission() }
        case .health:
            await HealthSync.shared.connect()
        case .watch:
            if let url = URL(string: "itms-watchs://") { openURL(url) }
        }
    }

    static func refresh() async {
        await PushManager.shared.refreshStatus()
        ScaleBluetooth.shared.refreshAuthorization()
    }

    private static func key(_ what: String, _ userId: String?) -> String { "ilw.setup.\(version).\(userId ?? "").\(what)" }

    static func shouldAutoPrompt(userId: String?) -> Bool {
        guard userId != nil, !UserDefaults.standard.bool(forKey: key("prompted", userId)),
              list().contains(where: { !$0.done }) else { return false }
        UserDefaults.standard.set(true, forKey: key("prompted", userId))
        return true
    }

    static func isSnoozed(_ userId: String?) -> Bool {
        UserDefaults.standard.double(forKey: key("snoozedUntil", userId)) > Date().timeIntervalSince1970
    }

    static func snooze(_ userId: String?) {
        UserDefaults.standard.set(Date().addingTimeInterval(7 * 86_400).timeIntervalSince1970, forKey: key("snoozedUntil", userId))
    }
}

private struct SetupRow: View {
    let step: SetupStep
    let busy: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.done ? "checkmark.circle.fill" : step.icon)
                .font(.system(size: 20))
                .foregroundStyle(step.done ? Theme.success : Theme.primary)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(step.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(step.done ? Theme.textMuted : Theme.textMain)
                if !step.done {
                    Text(step.detail).font(.system(size: 12)).foregroundStyle(Theme.textMuted).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if step.done {
                Text("On").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.success)
            } else {
                Button(action: onTap) {
                    Text(step.action)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.primary)
                        .foregroundStyle(.black)
                        .cornerRadius(100)
                }
                .disabled(busy)
                .accessibilityIdentifier("setup-\(step.kind.rawValue)")
            }
        }
        .padding(.vertical, 10)
    }
}

/// Sheet shown once per new feature set, and from the dashboard card.
struct SetupPromptView: View {
    @ObservedObject private var push = PushManager.shared
    @ObservedObject private var scale = ScaleBluetooth.shared
    @ObservedObject private var health = HealthSync.shared
    @ObservedObject private var watch = WatchLink.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var busy = false

    var body: some View {
        let steps = SetupSteps.list()
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Get the most out of iLoveWorks")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                        Text("Turn on what you'd like. iPhone asks your permission for each one, and you can change it later in Settings.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                        VStack(spacing: 0) {
                            ForEach(steps) { step in
                                SetupRow(step: step, busy: busy) {
                                    busy = true
                                    Task {
                                        await SetupSteps.run(step.kind, openURL: openURL)
                                        await SetupSteps.refresh()
                                        busy = false
                                    }
                                }
                                if step.id != steps.last?.id { Divider().overlay(Theme.border) }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(Theme.surface)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Setup")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(steps.allSatisfy(\.done) ? "Done" : "Not now") { dismiss() }
                        .accessibilityIdentifier("setup-close")
                }
            }
        }
        .task { await SetupSteps.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await SetupSteps.refresh() }
        }
    }
}

/// Compact dashboard card; hides itself when everything is on or the worker snoozes it.
struct SetupChecklistCard: View {
    @ObservedObject private var push = PushManager.shared
    @ObservedObject private var scale = ScaleBluetooth.shared
    @ObservedObject private var health = HealthSync.shared
    @ObservedObject private var watch = WatchLink.shared
    @EnvironmentObject private var session: SessionManager
    @State private var snoozed = false
    let onOpen: () -> Void

    var body: some View {
        let left = SetupSteps.list().filter { !$0.done }
        Group {
            if !left.isEmpty && !snoozed && !SetupSteps.isSnoozed(session.currentUser?.id) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.system(size: 20)).foregroundStyle(Theme.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finish setting up").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textMain)
                        Text(left.map(\.title).joined(separator: " · "))
                            .font(.system(size: 12)).foregroundStyle(Theme.textMuted).lineLimit(2)
                    }
                    Spacer()
                    Button("Open", action: onOpen)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .accessibilityIdentifier("setup-card-open")
                    Button {
                        SetupSteps.snooze(session.currentUser?.id)
                        snoozed = true
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textMuted)
                    }
                    .accessibilityLabel("Remind me later")
                    .accessibilityIdentifier("setup-card-snooze")
                }
                .padding(14)
                .background(Theme.primary.opacity(0.08))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.primary.opacity(0.3), lineWidth: 1))
                .accessibilityIdentifier("setup-card")
            }
        }
        .task { await SetupSteps.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await SetupSteps.refresh() }
        }
    }
}
#endif
