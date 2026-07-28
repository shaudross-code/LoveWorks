//
//  SessionManager.swift
//  iLoveWorks
//

import SwiftUI
import Combine

enum UserRole: String, Codable {
    case admin
    case worker
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    let avatarUrl: String?
}

struct LoginResponse: Codable {
    let user: User
    let accessToken: String
    let tokenType: String
}

class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = true
    
    static let shared = SessionManager()
    
    private init() {
        checkSession()
    }
    
    func checkSession() {
        Task {
            if let _ = KeychainService.shared.read(service: "TUE.iLoveWorks", account: "access_token") {
                do {
                    let user: User = try await APIClient.shared.request("/auth/me")
                    await MainActor.run {
                        self.currentUser = user
                        self.isLoading = false
                    }
                } catch {
                    print("Session check failed: \(error)")
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        let body = try JSONEncoder().encode(["email": email, "password": password])
        let response: LoginResponse = try await APIClient.shared.request("/auth/login", method: "POST", body: body)
        
        // Save token
        if let tokenData = response.accessToken.data(using: .utf8) {
            _ = KeychainService.shared.save(tokenData, service: "TUE.iLoveWorks", account: "access_token")
        }
        
        await MainActor.run {
            self.currentUser = response.user
        }
    }
    
    func logout() {
        _ = KeychainService.shared.delete(service: "TUE.iLoveWorks", account: "access_token")
        currentUser = nil
    }
}
