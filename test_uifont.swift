import Foundation
import CoreText
import AppKit // Use AppKit since we're on a Mac

func printFamilies(path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dataProviders = CGDataProvider(url: url as CFURL),
          let font = CGFont(dataProviders) else {
        print("Failed to load font at \(path)")
        return
    }
    
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterGraphicsFont(font, &error) {
        print("Error registering font: \(error.debugDescription)")
    } else {
        if let family = font.fullName {
            print("Successfully registered: \(family)")
        }
    }
}

printFamilies(path: "iLoveWorks/Fonts/Outfit-VariableFont_wght.ttf")
printFamilies(path: "iLoveWorks/Fonts/Manrope-VariableFont_wght.ttf")

print("Available AppKit families:")
for family in NSFontManager.shared.availableFontFamilies {
    if family.lowercased().contains("outfit") || family.lowercased().contains("manrope") {
        print(" - \(family)")
        if let members = NSFontManager.shared.availableMembers(ofFontFamily: family) {
            for member in members {
                print("   * \(member)")
            }
        }
    }
}
