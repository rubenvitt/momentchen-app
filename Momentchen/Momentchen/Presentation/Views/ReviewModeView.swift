//
//  ReviewModeView.swift
//  Momentchen
//
//  Created by Amelia (Dev Agent)
//

import SwiftUI
import SwiftData

/// Review Mode view - allows users to review and mark moments from different timeframes
/// Supports daily, weekly, monthly, yearly, and 5-year reviews
struct ReviewModeView: View {
    // MARK: - Properties

    @State private var viewModel: ReviewModeViewModel

    // MARK: - Initialization

    init(viewModel: ReviewModeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timeframe selector
                timeframePicker
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(systemBackgroundColor)

                Divider()

                // Period navigation
                periodNavigationBar
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(systemBackgroundColor)

                Divider()

                // Moments list
                Group {
                    if viewModel.isLoading && viewModel.moments.isEmpty {
                        loadingView
                    } else if viewModel.moments.isEmpty {
                        emptyStateView
                    } else {
                        momentsList
                    }
                }
            }
            .navigationTitle("Review-Modus")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadMomentsForSelectedTimeframe()
            }
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Subviews

    private var timeframePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReviewModeViewModel.ReviewTimeframe.allCases) { timeframe in
                    TimeframeChip(
                        timeframe: timeframe,
                        isSelected: viewModel.selectedTimeframe == timeframe
                    ) {
                        viewModel.updateTimeframe(timeframe)
                        Task {
                            await viewModel.loadMomentsForSelectedTimeframe()
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var periodNavigationBar: some View {
        HStack {
            Button(action: {
                viewModel.navigateToPrevious()
                Task {
                    await viewModel.loadMomentsForSelectedTimeframe()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(viewModel.canNavigateToPrevious ? .primary : .secondary)
            }
            .disabled(!viewModel.canNavigateToPrevious)

            Spacer()

            Text(viewModel.currentPeriodLabel)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: {
                viewModel.navigateToNext()
                Task {
                    await viewModel.loadMomentsForSelectedTimeframe()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(viewModel.canNavigateToNext ? .primary : .secondary)
            }
            .disabled(!viewModel.canNavigateToNext)
        }
    }

    private var momentsList: some View {
        List {
            Section {
                ForEach(viewModel.moments) { moment in
                    ReviewMomentRow(
                        moment: moment,
                        timeframe: viewModel.selectedTimeframe
                    ) {
                        Task {
                            await viewModel.toggleReviewMarker(for: moment)
                        }
                    }
                }
            } header: {
                Text(headerText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .overlay(alignment: .center) {
            if viewModel.isLoading && !viewModel.moments.isEmpty {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.background)
                                .shadow(radius: 10)
                        )
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Lade Momente...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if viewModel.selectedPeriodIndex == 0 {
                // Current period - show CTA
                ContentUnavailableView {
                    Label("Keine Momente", systemImage: "sparkles.rectangle.stack")
                } description: {
                    Text("Für diesen Zeitraum wurden noch keine Momente erfasst")
                } actions: {
                    Button {
                        // TODO: Navigate to create moment view
                        // This will be implemented in a future story
                    } label: {
                        Label("Moment erstellen", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // Historical period - no CTA
                ContentUnavailableView {
                    Label("Keine Momente", systemImage: "sparkles.rectangle.stack")
                } description: {
                    Text("Für diesen Zeitraum wurden keine Momente erfasst")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var headerText: String {
        let periodLabel = viewModel.currentPeriodLabel
        let count = viewModel.moments.count

        switch viewModel.selectedTimeframe {
        case .daily:
            return "\(count) Moment(e) am \(periodLabel)"
        case .weekly:
            return "\(count) Moment(e) in \(periodLabel)"
        case .monthly:
            return "\(count) Moment(e) im \(periodLabel)"
        case .yearly:
            return "\(count) Moment(e) in \(periodLabel)"
        case .fiveYear:
            return "\(count) Moment(e) in \(periodLabel)"
        }
    }

    private var systemBackgroundColor: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

// MARK: - Supporting Views

/// Timeframe selection chip
private struct TimeframeChip: View {
    let timeframe: ReviewModeViewModel.ReviewTimeframe
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: timeframe.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(timeframe.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : chipBackgroundColor)
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var chipBackgroundColor: Color {
        #if os(iOS)
        return Color(uiColor: .systemGray6)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

/// Review moment list row with star toggle
private struct ReviewMomentRow: View {
    let moment: Moment
    let timeframe: ReviewModeViewModel.ReviewTimeframe
    let onToggleStar: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Star toggle button
            Button(action: onToggleStar) {
                Image(systemName: isMarked ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundStyle(isMarked ? .yellow : .gray)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // Moment content
            VStack(alignment: .leading, spacing: 4) {
                Text(moment.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(moment.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(moment.type.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var isMarked: Bool {
        switch timeframe {
        case .daily: return moment.isDailyFavorite
        case .weekly: return moment.isWeeklyFavorite
        case .monthly: return moment.isMonthlyFavorite
        case .yearly: return moment.isYearlyFavorite
        case .fiveYear: return moment.isLifetimeMoment
        }
    }
}

// MARK: - Previews

#Preview("With Moments") {
    @Previewable @State var viewModel: ReviewModeViewModel = {
        let mockService = NotionAPIService.mock()
        let mockContext = try! ModelContext(
            ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        )

        let config = AppConfiguration.mock()
        mockContext.insert(config)

        let vm = ReviewModeViewModel(apiService: mockService, modelContext: mockContext)
        vm.moments = [
            Moment.mock(title: "Meeting mit Team", type: .erlebnis, isDailyFavorite: true),
            Moment.mock(title: "Neue Feature-Idee", type: .idee),
            Moment.mock(title: "Spaziergang im Park", type: .aktivität, isDailyFavorite: true)
        ]
        return vm
    }()

    ReviewModeView(viewModel: viewModel)
}

#Preview("Empty State") {
    @Previewable @State var viewModel: ReviewModeViewModel = {
        let mockService = NotionAPIService.mock()
        let mockContext = try! ModelContext(
            ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        )

        return ReviewModeViewModel(apiService: mockService, modelContext: mockContext)
    }()

    ReviewModeView(viewModel: viewModel)
}
