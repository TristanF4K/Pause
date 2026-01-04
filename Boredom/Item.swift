//
//  Item.swift
//  Boredom
//
//  Created by Tristan Srebot on 04.01.26.
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
