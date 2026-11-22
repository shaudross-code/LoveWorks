//
//  SessionManager.swift
//  iLoveWorks
//

import SwiftUI
import Combine

class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = true

    static let shared = SessionManager()

    private init() {
        checkSession()
    }

    func checkSession() {
        Task {
            if APIClient.shared.token != nil {
                do {
                    let user: User = try await APIClient.shared.request("/auth/me")
                    self.currentUser = user
                    self.didSignIn()
                } catch APIError.unauthorized {
                    _ = KeychainService.shared.delete(service: "TUE.iLoveWorks", account: "access_token")
                } catch {
                    print("Session check failed: \(error)")
                }
            }
            self.isLoading = false
        }
    }

    func login(email: String, password: String) async throws {
        let body = try JSONEncoder().encode(["email": email.trimmingCharacters(in: .whitespaces).lowercased(), "password": password])
        let response: LoginResponse = try await APIClient.shared.request("/auth/login", method: "POST", body: body)
        if let tokenData = response.accessToken.data(using: .utf8) {
            _ = KeychainService.shared.save(tokenData, service: "TUE.iLoveWorks", account: "access_token")
        }
        currentUser = response.user
        didSignIn()
    }

    func updateUser(_ user: User) {
        currentUser = user
    }

    private func didSignIn() {
        Task { await ThemeStore.shared.refresh() }
        PushManager.shared.signedIn()
        Task { await AlarmStore.shared.sync() }
        #if canImport(ActivityKit) && os(iOS)
        LiveActivityManager.shared.workerName = currentUser?.name ?? ""
        LiveActivityManager.shared.startObserving()
        #endif
        #if os(iOS) && canImport(HealthKit) && canImport(WatchConnectivity)
        WatchLink.shared.activate()
        HealthSync.shared.start()
        Task { await HealthSync.shared.refresh(upload: true) }
        #endif
    }

    func logout() {
        currentUser = nil
        AlarmStore.shared.clearLocal()
        #if os(iOS) && canImport(HealthKit)
        HealthSync.shared.signedOut()
        #endif
        #if canImport(ActivityKit) && os(iOS)
        Task { await LiveActivityManager.shared.endAll() }
        #endif
        Task {
            await PushManager.shared.signedOut()
            _ = KeychainService.shared.delete(service: "TUE.iLoveWorks", account: "access_token")
            await ThemeStore.shared.refresh()
        }
    }

    /// Clears the session without calling the server (account already deleted).
    func forgetSession() {
        PushManager.shared.forgetToken()
        AlarmStore.shared.clearLocal()
        #if os(iOS) && canImport(HealthKit)
        HealthSync.shared.signedOut()
        #endif
        _ = KeychainService.shared.delete(service: "TUE.iLoveWorks", account: "access_token")
        currentUser = nil
    }
}
