//
//  PushManager.swift
//  iLoveWorks
//
//  Real phone push alerts through Firebase Cloud Messaging.
//  The server (POST /api/push/register-device) sends to the FCM token we hand it.
//  Needs: the FirebaseMessaging Swift package (already added to the project), GoogleService-Info.plist,
//  and your APNs auth key uploaded in Firebase console → Project settings → Cloud Messaging.
//

import SwiftUI
import Combine
import UserNotifications
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

final class PushManager: ObservableObject {
    static let shared = PushManager()

    @Published private(set) var status: UNAuthorizationStatus = .notDetermined
    @Published private(set) var registered = false

    private let tokenKey = "fcm_token"
    private let optOutKey = "push_opted_out"
    let notificationDelegate = PushNotificationDelegate()

    private init() {}

    var token: String? { UserDefaults.standard.string(forKey: tokenKey) }
    var optedOut: Bool { UserDefaults.standard.bool(forKey: optOutKey) }
    var enabled: Bool { status == .authorized && registered && !optedOut }

    /// Called once from the app delegate at launch.
    func configure() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        #endif
        UNUserNotificationCenter.current().delegate = notificationDelegate
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = notificationDelegate
        #endif
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// After login: ask once (system prompt), or silently re-register if already allowed.
    func signedIn() {
        Task {
            await refreshStatus()
            if optedOut { return }
            if status == .notDetermined { _ = await enable() }
            else if status == .authorized || status == .provisional { registerWithApple() }
        }
    }

    /// Profile toggle on. Returns false when the user has blocked notifications in Settings.
    @discardableResult
    func enable() async -> Bool {
        UserDefaults.standard.set(false, forKey: optOutKey)
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshStatus()
        if granted { registerWithApple() }
        return granted
    }

    /// Profile toggle off.
    func disable() async {
        UserDefaults.standard.set(true, forKey: optOutKey)
        await unregisterFromServer()
    }

    func signedOut() async {
        await unregisterFromServer()
    }

    func forgetToken() {
        registered = false
    }
    func scheduleAlarm(id: String, title: String, body: String, timeString: String?, dueDayOfWeek: Int? = nil) {
        guard let timeString = timeString else {
            cancelAlarm(id: id)
            return
        }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Parse "HH:mm"
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }
              
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        if let dow = dueDayOfWeek {
            let appleWeekday = (dow + 2) > 7 ? 1 : (dow + 2)
            dateComponents.weekday = appleWeekday
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "alarm_\(id)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error)")
            }
        }
    }
    
    func cancelAlarm(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm_\(id)"])
    }


    private func registerWithApple() {
        #if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
        #if canImport(FirebaseMessaging)
        Task {
            do {
                if let token = try await Messaging.messaging().token() as String? {
                    await MainActor.run { self.didReceive(fcmToken: token) }
                }
            } catch {
                print("Failed to get FCM token: \(error)")
            }
        }
        #endif
    }

    func didReceive(fcmToken: String) {
        UserDefaults.standard.set(fcmToken, forKey: tokenKey)
        guard APIClient.shared.token != nil, !optedOut else { return }
        Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.send("/push/register-device", json: ["token": fcmToken, "platform": "ios"])
                registered = true
            } catch {
                print("Push token registration failed: \(error)")
            }
        }
    }

    private func unregisterFromServer() async {
        guard let t = token, APIClient.shared.token != nil else { registered = false; return }
        let _: EmptyResponse? = try? await APIClient.shared.send("/push/unregister-device", json: ["token": t, "platform": "ios"])
        registered = false
    }

    func sendTest() async throws {
        let _: EmptyResponse = try await APIClient.shared.request("/push/test", method: "POST")
    }
}

/// Firebase + notification-center callbacks. Kept off the main actor; hands results back to PushManager.
nonisolated final class PushNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        Task { @MainActor in
            await ThemeStore.shared.refresh()
            NotificationCenter.default.post(name: .pushOpened, object: nil)
        }
    }
}

#if canImport(FirebaseMessaging)
extension PushNotificationDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in PushManager.shared.didReceive(fcmToken: fcmToken) }
    }
}
#endif

extension Notification.Name {
    static let pushOpened = Notification.Name("iLoveWorksPushOpened")
}

#if canImport(UIKit)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        PushManager.shared.configure()
        Task {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                if #available(iOS 27.0, *) {
                    AVAudioSession.sharedInstance().activate(options: []) { success, error in
                        if let error = error {
                            print("Failed to configure audio session asynchronously: \(error)")
                        }
                    }
                } else {
                    try AVAudioSession.sharedInstance().setActive(true)
                }
            } catch {
                print("Failed to set audio session category: \(error)")
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
}
#endif
