//
//  APIClient.swift
//  iLoveWorks
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case server(status: Int, message: String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Bad address."
        case .unauthorized: return "Your session expired — please sign in again."
        case .server(_, let message): return message
        case .decodingError: return "The server sent something unexpected. Pull to refresh or try again."
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    // Debug and Release both talk to the live server (the web app's production backend).
    let baseURL = "https://labor-admin-hub.emergent.host/api"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private init() {}

    /// `body` is raw JSON data (already encoded).
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = body
        return try await perform(req)
    }

    /// Encodes `json` with snake_case keys and sends it.
    func send<T: Decodable, B: Encodable>(_ endpoint: String, method: String = "POST", json: B) async throws -> T {
        try await request(endpoint, method: method, body: try encoder.encode(json))
    }

    func upload<T: Decodable>(_ endpoint: String, fileData: Data, fileName: String, mimeType: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        var body = Data()
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\nContent-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        req.httpBody = body
        return try await perform(req)
    }

    private func perform<T: Decodable>(_ req: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.server(status: 0, message: "No response from server.") }
        if http.statusCode == 401 && req.url?.path.hasSuffix("/auth/login") == false { throw APIError.unauthorized }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.server(status: http.statusCode, message: Self.detail(from: data) ?? "Something went wrong (\(http.statusCode)).")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding \(T.self) from \(req.url?.path ?? "") failed: \(error)")
            throw APIError.decodingError("\(error)")
        }
    }

    /// FastAPI errors: {"detail": "text"} or {"detail": [{"msg": "..."}]}
    private static func detail(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let s = obj["detail"] as? String { return s }
        if let arr = obj["detail"] as? [[String: Any]] {
            return arr.compactMap { $0["msg"] as? String }.joined(separator: " ")
        }
        return nil
    }

    var token: String? {
        guard let data = KeychainService.shared.read(service: "TUE.iLoveWorks", account: "access_token") else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Absolute URL for /api/files/… paths (adds ?auth= so AsyncImage can load protected files).
    func fullURL(for path: String) -> String {
        if path.hasPrefix("http") { return path }
        var full = baseURL.replacingOccurrences(of: "/api", with: "") + path
        if let token = token {
            full += (full.contains("?") ? "&" : "?") + "auth=\(token)"
        }
        return full
    }
}
