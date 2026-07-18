//
//  Item.swift
//  iLoveWorks
//
//  Created by Wick Ross on 7/18/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
