//
//  iLoveWorksApp.swift
//  iLoveWorks
//

import SwiftUI

@main
struct iLoveWorksApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var themeStore = ThemeStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if sessionManager.isLoading {
                        ZStack {
                            Theme.background.ignoresSafeArea()
                            ProgressView()
                                .tint(Theme.lovePink)
                        }
                    } else if let user = sessionManager.currentUser {
                        if user.role == .admin {
                            AdminDashboardView()
                        } else {
                            WorkerDashboardView()
                        }
                    } else {
                        LoginView()
                    }
                }
                .environmentObject(sessionManager)
                .accentColor(Theme.lovePink)
                .tint(Theme.lovePink)

                HolidayFloaters()
            }
            // Rebuild colours when the holiday look changes (Theme.primary / lovePink read the store).
            .id(themeStore.effective)
            .preferredColorScheme(.dark)
            .task {
                await themeStore.refresh()
                // Re-check every 30 minutes so holiday windows switch on/off without a relaunch.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1800))
                    await themeStore.refresh()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await themeStore.refresh() } }
            }
        }
    }
}
