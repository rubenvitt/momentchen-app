//
//  Item.swift
//  Momentchen
//
//  Created by Ruben Vitt on 22.10.25.
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
