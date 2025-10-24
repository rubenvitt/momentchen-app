//
//  NotificationManager.swift
//  Momentchen
//
//  Created by Amelia (Dev Agent)
//

import Foundation
import UserNotifications
import OSLog

/// Manages local push notifications for review reminders
/// Schedules daily, weekly, monthly, yearly, and 5-year review notifications
actor NotificationManager {
    // MARK: - Types

    enum NotificationType: String {
        case daily = "daily-review"
        case weekly = "weekly-review"
        case monthly = "monthly-review"
        case yearly = "yearly-review"
        case fiveYear = "five-year-review"

        var title: String {
            switch self {
            case .daily: return "Täglicher Review"
            case .weekly: return "Wöchentlicher Review"
            case .monthly: return "Monatlicher Review"
            case .yearly: return "Jährlicher Review"
            case .fiveYear: return "5-Jahres Review"
            }
        }

        var body: String {
            switch self {
            case .daily: return "Zeit, die Momente von gestern zu markieren ✨"
            case .weekly: return "Welche Momente der letzten Woche waren besonders?"
            case .monthly: return "Reflektiere über die Highlights des letzten Monats"
            case .yearly: return "Ein Jahr voller Momente - welche bleiben?"
            case .fiveYear: return "Deine wichtigsten Momente der letzten 5 Jahre"
            }
        }
    }

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.momentchen.app", category: "Notifications")

    // MARK: - Public Methods

    /// Request notification permissions from user
    /// - Returns: True if permissions granted
    func requestAuthorization() async throws -> Bool {
        logger.info("Requesting notification authorization")

        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

        logger.info("Notification authorization: \(granted ? "granted" : "denied")")
        return granted
    }

    /// Check current notification authorization status
    /// - Returns: Authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// Schedule all review notifications
    /// - Parameters:
    ///   - dailyTime: Time for daily notifications (hour and minute)
    ///   - weeklyDay: Day of week for weekly (1=Monday, 7=Sunday)
    ///   - monthlyDay: Day of month for monthly (1-28)
    ///   - yearlyMonth: Month for yearly (1-12)
    ///   - yearlyDay: Day for yearly (1-31)
    func scheduleAllReviewNotifications(
        dailyTime: DateComponents,
        weeklyDay: Int,
        monthlyDay: Int,
        yearlyMonth: Int,
        yearlyDay: Int
    ) async throws {
        logger.info("Scheduling all review notifications")

        // Remove existing notifications first
        await cancelAllReviewNotifications()

        // Daily notification
        try await scheduleDailyNotification(at: dailyTime)

        // Weekly notification
        try await scheduleWeeklyNotification(on: weeklyDay, at: dailyTime)

        // Monthly notification
        try await scheduleMonthlyNotification(on: monthlyDay, at: dailyTime)

        // Yearly notification
        try await scheduleYearlyNotification(month: yearlyMonth, day: yearlyDay, at: dailyTime)

        // 5-Year notification (special logic - trigger on block boundaries)
        try await scheduleFiveYearNotification(month: 1, day: 1, at: dailyTime)

        logger.info("All review notifications scheduled successfully")
    }

    /// Cancel all review notifications
    func cancelAllReviewNotifications() async {
        logger.info("Cancelling all review notifications")

        let identifiers = NotificationType.allCases.map { $0.rawValue }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        logger.info("All review notifications cancelled")
    }

    /// Get pending notification requests
    /// - Returns: Array of pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Private Methods

    /// Schedule daily review notification
    private func scheduleDailyNotification(at time: DateComponents) async throws {
        logger.debug("Scheduling daily notification at \(time.hour ?? 20):\(time.minute ?? 0)")

        let content = createNotificationContent(for: .daily)

        var dateComponents = DateComponents()
        dateComponents.hour = time.hour ?? 20
        dateComponents.minute = time.minute ?? 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.daily.rawValue,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        logger.debug("Daily notification scheduled")
    }

    /// Schedule weekly review notification
    private func scheduleWeeklyNotification(on weekday: Int, at time: DateComponents) async throws {
        logger.debug("Scheduling weekly notification on weekday \(weekday)")

        let content = createNotificationContent(for: .weekly)

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = time.hour ?? 20
        dateComponents.minute = time.minute ?? 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.weekly.rawValue,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        logger.debug("Weekly notification scheduled")
    }

    /// Schedule monthly review notification
    private func scheduleMonthlyNotification(on day: Int, at time: DateComponents) async throws {
        logger.debug("Scheduling monthly notification on day \(day)")

        let content = createNotificationContent(for: .monthly)

        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.hour = time.hour ?? 20
        dateComponents.minute = time.minute ?? 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.monthly.rawValue,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        logger.debug("Monthly notification scheduled")
    }

    /// Schedule yearly review notification
    private func scheduleYearlyNotification(month: Int, day: Int, at time: DateComponents) async throws {
        logger.debug("Scheduling yearly notification on \(month)/\(day)")

        let content = createNotificationContent(for: .yearly)

        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = time.hour ?? 20
        dateComponents.minute = time.minute ?? 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.yearly.rawValue,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        logger.debug("Yearly notification scheduled")
    }

    /// Schedule 5-year review notification (beginning of 5-year blocks)
    private func scheduleFiveYearNotification(month: Int, day: Int, at time: DateComponents) async throws {
        logger.debug("Scheduling 5-year notification")

        let content = createNotificationContent(for: .fiveYear)

        // Calculate next 5-year block boundary (2025, 2030, 2035, etc.)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let nextBlockStart = ((currentYear / 5) + 1) * 5

        var dateComponents = DateComponents()
        dateComponents.year = nextBlockStart
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = time.hour ?? 20
        dateComponents.minute = time.minute ?? 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationType.fiveYear.rawValue,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        logger.debug("5-year notification scheduled for year \(nextBlockStart)")
    }

    /// Create notification content for specific type
    private func createNotificationContent(for type: NotificationType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default
        content.categoryIdentifier = "REVIEW_REMINDER"
        content.userInfo = ["type": type.rawValue]

        return content
    }
}

// MARK: - Notification Type Extension

extension NotificationManager.NotificationType: CaseIterable {}
