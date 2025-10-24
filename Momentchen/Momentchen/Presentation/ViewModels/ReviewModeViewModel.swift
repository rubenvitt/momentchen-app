//
//  ReviewModeViewModel.swift
//  Momentchen
//
//  Created by Amelia (Dev Agent)
//

import Foundation
import SwiftData
import OSLog

/// View model for Review Mode
/// Manages loading and filtering moments by different review timeframes
@Observable
final class ReviewModeViewModel {
    // MARK: - Types

    enum ReviewTimeframe: String, CaseIterable, Identifiable {
        case daily = "Täglich"
        case weekly = "Wöchentlich"
        case monthly = "Monatlich"
        case yearly = "Jährlich"
        case fiveYear = "5-Jahres"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .daily: return "sun.max.fill"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar"
            case .yearly: return "sparkles"
            case .fiveYear: return "star.fill"
            }
        }
    }

    // MARK: - Types

    struct DateRange {
        let start: Date
        let end: Date
    }

    // MARK: - Properties

    var selectedTimeframe: ReviewTimeframe = .daily
    var moments: [Moment] = []
    var isLoading = false
    var errorMessage: String?

    // Period navigation
    private(set) var availablePeriods: [DateRange] = []
    var selectedPeriodIndex: Int = 0

    private let apiService: NotionAPIServiceProtocol
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.momentchen.app", category: "ReviewMode")
    private let projectRepository: ProjectRepository
    private let lifeAreaRepository: LifeAreaRepository

    // MARK: - Initialization

    init(
        apiService: NotionAPIServiceProtocol,
        modelContext: ModelContext,
        projectRepository: ProjectRepository? = nil,
        lifeAreaRepository: LifeAreaRepository? = nil
    ) {
        self.apiService = apiService
        self.modelContext = modelContext

        // Use provided repositories or create new ones
        self.projectRepository = projectRepository ?? ProjectRepository(
            modelContext: modelContext,
            apiService: apiService
        )
        self.lifeAreaRepository = lifeAreaRepository ?? LifeAreaRepository(
            modelContext: modelContext,
            apiService: apiService
        )
    }

    // MARK: - Computed Properties

    var canNavigateToPrevious: Bool {
        selectedPeriodIndex < availablePeriods.count - 1
    }

    var canNavigateToNext: Bool {
        selectedPeriodIndex > 0
    }

    var currentPeriodLabel: String {
        guard selectedPeriodIndex < availablePeriods.count else { return "" }
        let period = availablePeriods[selectedPeriodIndex]
        return formatPeriodLabel(period: period, timeframe: selectedTimeframe)
    }

    // MARK: - Public Methods

    /// Navigate to previous period (older)
    func navigateToPrevious() {
        guard canNavigateToPrevious else { return }
        selectedPeriodIndex += 1
    }

    /// Navigate to next period (newer)
    func navigateToNext() {
        guard canNavigateToNext else { return }
        selectedPeriodIndex -= 1
    }

    /// Update timeframe and reset to current period
    func updateTimeframe(_ newTimeframe: ReviewTimeframe) {
        selectedTimeframe = newTimeframe
        availablePeriods = calculateAvailablePeriods(for: newTimeframe)
        selectedPeriodIndex = 0
    }

    /// Load moments for the selected timeframe
    @MainActor
    func loadMomentsForSelectedTimeframe() async {
        // Calculate available periods if needed
        if availablePeriods.isEmpty || selectedPeriodIndex >= availablePeriods.count {
            availablePeriods = calculateAvailablePeriods(for: selectedTimeframe)
            selectedPeriodIndex = 0
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            moments = try await loadMoments(for: selectedTimeframe)
            logger.info("Loaded \(self.moments.count) moments for \(self.selectedTimeframe.rawValue)")
        } catch {
            logger.error("Failed to load moments: \(error.localizedDescription)")
            errorMessage = "Fehler beim Laden der Momente: \(error.localizedDescription)"
        }
    }

    /// Toggle review marker for a specific moment
    @MainActor
    func toggleReviewMarker(for moment: Moment) async {
        guard let configuration = try? modelContext.fetch(FetchDescriptor<AppConfiguration>()).first else {
            errorMessage = "Keine Konfiguration gefunden"
            return
        }

        do {
            // Determine which checkbox to toggle based on selected timeframe
            let properties: [String: NotionProperty]

            switch selectedTimeframe {
            case .daily:
                properties = MomentMapper.toReviewCheckboxProperties(
                    isDailyFavorite: !moment.isDailyFavorite
                )
            case .weekly:
                properties = MomentMapper.toReviewCheckboxProperties(
                    isWeeklyFavorite: !moment.isWeeklyFavorite
                )
            case .monthly:
                properties = MomentMapper.toReviewCheckboxProperties(
                    isMonthlyFavorite: !moment.isMonthlyFavorite
                )
            case .yearly:
                properties = MomentMapper.toReviewCheckboxProperties(
                    isYearlyFavorite: !moment.isYearlyFavorite
                )
            case .fiveYear:
                properties = MomentMapper.toReviewCheckboxProperties(
                    isLifetimeMoment: !moment.isLifetimeMoment
                )
            }

            // Update via Notion API
            _ = try await apiService.updatePage(
                token: configuration.notionToken,
                pageId: moment.id,
                properties: properties
            )

            // Reload moments to reflect change
            await loadMomentsForSelectedTimeframe()

            logger.info("Toggled review marker for moment: \(moment.id)")
        } catch {
            logger.error("Failed to toggle review marker: \(error.localizedDescription)")
            errorMessage = "Fehler beim Aktualisieren: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Load moments for specific timeframe
    private func loadMoments(for timeframe: ReviewTimeframe) async throws -> [Moment] {
        guard let configuration = try? modelContext.fetch(FetchDescriptor<AppConfiguration>()).first else {
            throw NSError(domain: "ReviewMode", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Konfiguration gefunden"])
        }

        // Build filter based on timeframe
        let dateRange = calculateDateRange(for: timeframe)
        var filters: [NotionFilter] = [
            .date("Zeitpunkt", .onOrAfter(dateRange.start)),
            .date("Zeitpunkt", .onOrBefore(dateRange.end))
        ]

        // Add hierarchical review level filter
        // Each timeframe shows only moments marked as favorites from the previous level
        switch timeframe {
        case .daily:
            // No additional filter - show ALL moments from yesterday
            break

        case .weekly:
            // Only show moments marked as daily favorites
            filters.append(.checkbox("⭐ Tagesfavorit", .equals(true)))

        case .monthly:
            // Only show moments marked as weekly favorites
            filters.append(.checkbox("⭐ Wochenfavorit", .equals(true)))

        case .yearly:
            // Only show moments marked as monthly favorites
            filters.append(.checkbox("⭐ Monatsfavorit", .equals(true)))

        case .fiveYear:
            // Only show moments marked as yearly favorites
            filters.append(.checkbox("⭐ Jahresfavorit", .equals(true)))
        }

        let filter = NotionFilter.and(filters)

        // Sort by timestamp descending
        let sorts = [NotionSort(property: "Zeitpunkt", timestamp: nil, direction: .descending)]

        // Query Notion API
        let pages = try await apiService.queryDatabase(
            token: configuration.notionToken,
            databaseId: configuration.momentsDatabaseId,
            filter: filter,
            sorts: sorts,
            pageSize: 100
        )

        // Load projects and life areas for category resolution using cache-first pattern
        let projects = await projectRepository.getProjects(filterActive: true)
        let lifeAreas = await lifeAreaRepository.getLifeAreas(filterActive: true)

        // Map to domain models with category resolution
        let moments = MomentMapper.toDomain(pages, projects: projects, lifeAreas: lifeAreas)

        return moments
    }

    /// Calculate date range for timeframe using selected period index
    private func calculateDateRange(for timeframe: ReviewTimeframe) -> (start: String, end: String) {
        guard selectedPeriodIndex < availablePeriods.count else {
            // Fallback to first period if index is invalid
            let formatter = ISO8601DateFormatter()
            let now = Date()
            return (formatter.string(from: now), formatter.string(from: now))
        }

        let period = availablePeriods[selectedPeriodIndex]
        let formatter = ISO8601DateFormatter()

        return (formatter.string(from: period.start), formatter.string(from: period.end))
    }

    /// Calculate available periods for navigation (3 periods per timeframe)
    private func calculateAvailablePeriods(for timeframe: ReviewTimeframe) -> [DateRange] {
        let calendar = Calendar.current
        let now = Date()

        switch timeframe {
        case .daily:
            // Return 3 days: today, yesterday, 2 days ago
            return (0...2).map { offset in
                let date = calendar.date(byAdding: .day, value: -offset, to: now)!
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
                return DateRange(start: startOfDay, end: endOfDay)
            }

        case .weekly:
            // Return 3 weeks
            return (0...2).map { offset in
                let weekDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: now)!
                let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: weekDate).date!
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!.addingTimeInterval(-1)
                return DateRange(start: startOfWeek, end: endOfWeek)
            }

        case .monthly:
            // Return 3 months
            return (0...2).map { offset in
                let monthDate = calendar.date(byAdding: .month, value: -offset, to: now)!
                let startOfMonth = calendar.dateComponents([.calendar, .year, .month], from: monthDate).date!
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!.addingTimeInterval(-1)
                return DateRange(start: startOfMonth, end: endOfMonth)
            }

        case .yearly:
            // Return 3 years
            return (0...2).map { offset in
                let yearDate = calendar.date(byAdding: .year, value: -offset, to: now)!
                let startOfYear = calendar.dateComponents([.calendar, .year], from: yearDate).date!
                let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!.addingTimeInterval(-1)
                return DateRange(start: startOfYear, end: endOfYear)
            }

        case .fiveYear:
            // Return 3 five-year blocks
            let currentYear = calendar.component(.year, from: now)
            return (0...2).map { offset in
                let targetYear = currentYear - (offset * 5)
                let blockStart = (targetYear / 5) * 5
                let blockEnd = blockStart + 4

                let startDate = calendar.date(from: DateComponents(year: blockStart, month: 1, day: 1))!
                let endDate = calendar.date(from: DateComponents(year: blockEnd, month: 12, day: 31, hour: 23, minute: 59))!

                return DateRange(start: startDate, end: endDate)
            }
        }
    }

    /// Format period label for display
    private func formatPeriodLabel(period: DateRange, timeframe: ReviewTimeframe) -> String {
        let calendar = Calendar.current
        let now = Date()

        switch timeframe {
        case .daily:
            if calendar.isDateInToday(period.start) {
                return "Heute"
            } else if calendar.isDateInYesterday(period.start) {
                return "Gestern"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                return formatter.string(from: period.start)
            }

        case .weekly:
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            let startStr = formatter.string(from: period.start)
            let endStr = formatter.string(from: period.end)
            return "\(startStr) - \(endStr)"

        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "de_DE")
            return formatter.string(from: period.start)

        case .yearly:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return formatter.string(from: period.start)

        case .fiveYear:
            let startYear = calendar.component(.year, from: period.start)
            let endYear = calendar.component(.year, from: period.end)
            return "\(startYear) - \(endYear)"
        }
    }
}
