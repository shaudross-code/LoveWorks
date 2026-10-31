//
//  Theme.swift
//  iLoveWorks
//

import SwiftUI

struct Theme {
    static let background = Color(hex: "#09090B")
    static let surface = Color(hex: "#121214")
    static let surfaceHover = Color(hex: "#1A1A1D")
    static let primary = Color(hex: "#FACC15") // Gold remains as primary accent
    static let primaryHover = Color(hex: "#FDE047")
    static let secondary = Color(hex: "#27272A")
    static let textMain = Color(hex: "#FFFFFF")
    static let textMuted = Color(hex: "#A1A1AA")
    static let success = Color(hex: "#4ADE80")
    static let danger = Color(hex: "#F87171")
    static let border = Color(hex: "#FACC15").opacity(0.2)
    
    // LoveWorks Rebrand Colors
    static let lovePink = Color(hex: "#F472B6") // Pink-rose for rebrand
    static let loveGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#F472B6"), Color(hex: "#E11D48")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    static let zinc = Color(hex: "#27272A")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
