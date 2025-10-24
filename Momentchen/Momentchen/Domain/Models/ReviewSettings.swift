//
//  ReviewSettings.swift
//  Momentchen
//
//  Created by Amelia (Dev Agent)
//

import Foundation
import SwiftData

@Model
final class ReviewSettings {
    @Attribute(.unique) var id: String
    var dailyNotificationTime: Date
    var weeklyNotificationDay: Int // 1=Monday, 7=Sunday
    var monthlyNotificationDay: Int // 1-28
    var yearlyNotificationMonth: Int // 1-12
    var yearlyNotificationDay: Int // 1-31

    init(
        dailyNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date(),
        weeklyNotificationDay: Int = 7, // Sunday
        monthlyNotificationDay: Int = 28, // Last safe day of month
        yearlyNotificationMonth: Int = 12, // December
        yearlyNotificationDay: Int = 31 // New Year's Eve
    ) {
        self.id = "global" // Singleton pattern
        self.dailyNotificationTime = dailyNotificationTime
        self.weeklyNotificationDay = weeklyNotificationDay
        self.monthlyNotificationDay = monthlyNotificationDay
        self.yearlyNotificationMonth = yearlyNotificationMonth
        self.yearlyNotificationDay = yearlyNotificationDay
    }
}
