//
//  ProfileView.swift
//  iLoveWorks
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var workerViewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @ObservedObject private var push = PushManager.shared
    @State private var testMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PageHeader(eyebrow: "ACCOUNT", title: "Profile")

                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionManager.currentUser?.name ?? "")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.textMain)
                            Text(sessionManager.currentUser?.email ?? "")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .padding(.horizontal)

                        VStack(spacing: 10) {
                            NavigationLink(destination: AlarmsView()) {
                                ProfileRow(icon: "alarm.fill", label: "Alarms", color: Theme.primary) {
                                    Image(systemName: "chevron.right").foregroundStyle(Theme.textMuted)
                                }
                            }
                            #if os(iOS) && canImport(HealthKit) && canImport(WatchConnectivity)
                            NavigationLink(destination: HealthView()) {
                                ProfileRow(icon: "applewatch", label: "Apple Watch, Scale & Health", color: Theme.lovePink) {
                                    Image(systemName: "chevron.right").foregroundStyle(Theme.textMuted)
                                }
                            }
                            #endif
                            NavigationLink(destination: WorkerAwardsView(viewModel: workerViewModel)) {
                                ProfileRow(icon: "trophy.fill", label: "Trophy case", color: Theme.lovePink) {
                                    Image(systemName: "chevron.right").foregroundStyle(Theme.textMuted)
                                }
                            }
                            ProfileRow(icon: "bell.badge.fill", label: "Push alerts", color: .orange) {
                                Toggle("", isOn: Binding(
                                    get: { push.enabled },
                                    set: { on in Task { if on { _ = await push.enable() } else { await push.disable() } } }
                                ))
                                .labelsHidden()
                            }
                            Button(action: sendTest) {
                                ProfileRow(icon: "paperplane.fill", label: "Send test alert", color: .blue) {
                                    Text(testMessage).font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                                }
                            }
                            Button(action: { sessionManager.logout() }) {
                                ProfileRow(icon: "rectangle.portrait.and.arrow.right", label: "Log out", color: Theme.danger) {
                                    EmptyView()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        Text("Test alerts come from the server, so they only arrive once the Apple push key is uploaded in Firebase. Alarms don't need that: they ring from this phone.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .task { await push.refreshStatus() }
        }
    }

    private func sendTest() {
        testMessage = "Sending…"
        Task {
            do {
                try await PushManager.shared.sendTest()
                testMessage = "Sent"
            } catch {
                testMessage = error.localizedDescription
            }
        }
    }
}
