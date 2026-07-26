//
//  iLoveWorksApp.swift
//  iLoveWorks
//

import SwiftUI

@main
struct iLoveWorksApp: App {
    @StateObject private var sessionManager = SessionManager.shared
    
    var body: some Scene {
        WindowGroup {
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
                            .environmentObject(sessionManager)
                            .accentColor(Theme.lovePink)
                    } else {
                        WorkerDashboardView()
                            .environmentObject(sessionManager)
                            .accentColor(Theme.lovePink)
                    }
                } else {
                    LoginView()
                        .environmentObject(sessionManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
