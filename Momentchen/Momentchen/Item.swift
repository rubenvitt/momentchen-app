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
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var isStarred: Bool
    var starredAt: Date?

    init(timestamp: Date) {
        self.id = UUID()
        self.timestamp = timestamp
        self.isStarred = false
        self.starredAt = nil
    }
}
