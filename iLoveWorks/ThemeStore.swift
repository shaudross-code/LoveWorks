//
//  ThemeStore.swift
//  iLoveWorks
//
//  Holiday look shared with the web app (GET /api/theme). The last answer is cached so the app
//  opens straight in the right look, keeps it when the server is unreachable, and drops it once
//  the holiday window has ended.
//

import SwiftUI
import Combine

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published private(set) var state: ThemeState?
    @Published private(set) var effective: String
    private var retryTask: Task<Void, Never>?

    private init() {
        let cached = ThemeCache.load()
        state = cached
        effective = ThemeCache.effectiveKey(cached)
    }

    var palette: ThemePalette { ThemePalette.forKey(effective) }

    /// Holiday name/greeting/emojis, nil for the default look.
    var theme: ThemeInfo? { effective == "default" ? nil : state?.theme }

    func refresh() async {
        retryTask?.cancel()
        do {
            let s: ThemeState = try await APIClient.shared.request("/theme")
            apply(s)
        } catch {
            effective = ThemeCache.effectiveKey(state)
            retryTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(20))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    func setMode(_ mode: String) async throws {
        let s: ThemeState = try await APIClient.shared.send("/theme", method: "PUT", json: ["mode": mode])
        apply(s)
    }

    private func apply(_ s: ThemeState) {
        ThemeCache.save(s)
        state = s
        let key = ThemeCache.effectiveKey(s)
        if key != effective { effective = key }
    }
}
