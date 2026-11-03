//
//  iLoveWorksApp.swift
//  iLoveWorks
//

import SwiftUI
import UserNotifications

#if canImport(UIKit)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let err = error {
                print("Failed to request authorization: \(err)")
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
        // Typically here you would send the token to your backend or SessionManager
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
#endif

@main
struct iLoveWorksApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
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
