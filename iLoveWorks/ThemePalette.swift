//
//  ThemePalette.swift
//  iLoveWorks
//
//  Holiday colours — the same swaps the web app makes (gold → primary, pink → accent).
//

import Foundation

struct ThemePalette: Equatable {
    let primary: String      // web yellow-400
    let primaryHover: String // web yellow-300
    let accent: String       // web pink-400
    let accentDeep: String   // gradient end

    static let standard = ThemePalette(primary: "#FACC15", primaryHover: "#FDE047", accent: "#F472B6", accentDeep: "#E11D48")

    static let holidays: [String: ThemePalette] = [
        "halloween": .init(primary: "#F97316", primaryHover: "#FDBA74", accent: "#A78BFA", accentDeep: "#7C3AED"),
        "thanksgiving": .init(primary: "#F59E0B", primaryHover: "#FCD34D", accent: "#FB923C", accentDeep: "#C2410C"),
        "christmas": .init(primary: "#F87171", primaryHover: "#FCA5A5", accent: "#4ADE80", accentDeep: "#16A34A"),
        "newyear": .init(primary: "#FACC15", primaryHover: "#FDE047", accent: "#38BDF8", accentDeep: "#0284C7"),
        "valentines": .init(primary: "#FB7185", primaryHover: "#FDA4AF", accent: "#F472B6", accentDeep: "#E11D48"),
        "stpatricks": .init(primary: "#4ADE80", primaryHover: "#86EFAC", accent: "#34D399", accentDeep: "#059669"),
        "easter": .init(primary: "#C4B5FD", primaryHover: "#DDD6FE", accent: "#6EE7B7", accentDeep: "#10B981"),
        "july4": .init(primary: "#F87171", primaryHover: "#FCA5A5", accent: "#60A5FA", accentDeep: "#2563EB"),
    ]

    static func forKey(_ key: String) -> ThemePalette { holidays[key] ?? standard }
}

enum ThemeCache {
    static let storageKey = "lastTheme"

    /// The look to show for a cached/server state; a cached holiday expires once its window has ended.
    static func effectiveKey(_ state: ThemeState?, today: Date = Date()) -> String {
        guard let s = state else { return "default" }
        if let ends = s.endsOn, let end = APIDate.parse(ends) {
            let lastDay = Calendar.current.startOfDay(for: end)
            if Calendar.current.startOfDay(for: today) > lastDay { return "default" }
        }
        return ThemePalette.holidays[s.effective] == nil ? "default" : s.effective
    }

    static func load(_ defaults: UserDefaults = .standard) -> ThemeState? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(ThemeState.self, from: data)
    }

    static func save(_ state: ThemeState, _ defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: storageKey) }
    }
}
