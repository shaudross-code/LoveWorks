//
//  APIClient.swift
//  iLoveWorks
//

import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case unauthorized
    case serverError(String)
    case decodingError
}

class APIClient {
    static let shared = APIClient()
    // Debug builds (Run from Xcode) use the local dev server; Release builds
    // (Archive for the App Store / TestFlight) use production automatically.
#if DEBUG
    private let baseURL = "http://127.0.0.1:8001/api"
#else
    private let baseURL = "https://labor-admin-hub.emergent.host/api"
#endif
    
    private init() {}
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Inject JWT if available
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    private func getToken() -> String? {
        if let tokenData = KeychainService.shared.read(service: "TUE.iLoveWorks", account: "access_token") {
            return String(data: tokenData, encoding: .utf8)
        }
        return nil
    }
    
    func fullURL(for path: String) -> String {
        if path.hasPrefix("http") { return path }
        var full = baseURL.replacingOccurrences(of: "/api", with: "") + path
        
        // Append auth token for protected files per SPEC
        if let token = getToken() {
            let separator = full.contains("?") ? "&" : "?"
            full += "\(separator)auth=\(token)"
        }
        
        return full
    }
}
