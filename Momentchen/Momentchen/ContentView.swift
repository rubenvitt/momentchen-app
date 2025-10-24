//
//  ContentView.swift
//  Momentchen
//
//  Created by Ruben Vitt on 22.10.25.
//

import SwiftUI
import SwiftData

/// Root content view that determines whether to show setup or main app
/// Checks for AppConfiguration to decide navigation flow
struct ContentView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [AppConfiguration]

    @State private var isCheckingConfig = true

    private var hasConfiguration: Bool {
        !configurations.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isCheckingConfig {
                loadingView
            } else if hasConfiguration {
                mainAppView
            } else {
                setupView
            }
        }
        .task {
            // Small delay to allow SwiftData to load
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            isCheckingConfig = false
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Momentchen")
                .font(.title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var setupView: some View {
        let apiService = NotionAPIService()
        let viewModel = SetupViewModel(
            apiService: apiService,
            modelContext: modelContext
        )

        return SetupView(viewModel: viewModel)
    }

    private var mainAppView: some View {
        let apiService = NotionAPIService()

        return MainTabView(apiService: apiService)
            .preferredColorScheme(configurations.first?.theme.colorScheme)
    }
}

// MARK: - Previews

#Preview("Setup Flow") {
    ContentView()
        .modelContainer(for: AppConfiguration.self, inMemory: true)
}

#Preview("Main App") {
    let container = try! ModelContainer(
        for: AppConfiguration.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = ModelContext(container)
    let config = AppConfiguration.mock()
    context.insert(config)

    return ContentView()
        .modelContainer(container)
        .environment(\.modelContext, context)
}
