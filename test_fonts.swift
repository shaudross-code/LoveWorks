import SwiftUI
import AppKit

for family in NSFontManager.shared.availableFontFamilies {
    if family.contains("Outfit") || family.contains("Manrope") {
        print("Family: \(family)")
        for member in NSFontManager.shared.availableMembers(ofFontFamily: family) ?? [] {
            print("  \(member)")
        }
    }
}
