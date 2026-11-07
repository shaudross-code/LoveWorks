import Foundation
import CoreGraphics
import CoreText

func dumpFontNames(path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dataProviders = CGDataProvider(url: url as CFURL),
          let font = CGFont(dataProviders) else {
        print("Failed to load font at \(path)")
        return
    }
    
    if let postScriptName = font.postScriptName {
        print("PostScript Name: \(postScriptName)")
    }
    if let fullName = font.fullName {
        print("Full Name: \(fullName)")
    }
}

dumpFontNames(path: "iLoveWorks/Fonts/Outfit-VariableFont_wght.ttf")
dumpFontNames(path: "iLoveWorks/Fonts/Manrope-VariableFont_wght.ttf")
