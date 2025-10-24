//
//  MainTabView.swift
//  Momentchen
//
//  Created by Amelia (Dev Agent)
//

import SwiftUI
import SwiftData

/// Main tab-based navigation container
/// Provides access to Moments list and Review mode
struct MainTabView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext

    private let apiService: NotionAPIService

    // MARK: - Initialization

    init(apiService: NotionAPIService) {
        self.apiService = apiService
    }

    // MARK: - Body

    var body: some View {
        TabView {
            // Today's Moments Tab
            momentsTab
                .tabItem {
                    Label("Momente", systemImage: "sparkles")
                }

            // Review Mode Tab
            reviewTab
                .tabItem {
                    Label("Reviews", systemImage: "star.circle.fill")
                }
        }
    }

    // MARK: - Tab Content

    private var momentsTab: some View {
        let viewModel = MomentListViewModel(
            apiService: apiService,
            modelContext: modelContext
        )

        return MomentListView(viewModel: viewModel)
    }

    private var reviewTab: some View {
        let viewModel = ReviewModeViewModel(
            apiService: apiService,
            modelContext: modelContext
        )

        return ReviewModeView(viewModel: viewModel)
    }
}

// MARK: - Previews

#Preview {
    let container = try! ModelContainer(
        for: AppConfiguration.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = ModelContext(container)
    let config = AppConfiguration.mock()
    context.insert(config)

    return MainTabView(apiService: NotionAPIService.mock())
        .modelContainer(container)
        .environment(\.modelContext, context)
}
