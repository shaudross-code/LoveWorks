//
//  FontStyles.swift
//  iLoveWorks
//

import SwiftUI

struct FontStyles {
    // We fall back to standard iOS System fonts here explicitly in case the 
    // project file script fails, but normally we would load the TTF here.
    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }
    
    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
}
