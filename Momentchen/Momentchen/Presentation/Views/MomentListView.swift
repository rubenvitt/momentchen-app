//
//  MomentListView.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI
import SwiftData

/// Main view displaying today's moments
/// Supports pull-to-refresh and auto-refresh
struct MomentListView: View {
    // MARK: - Properties

    @State private var viewModel: MomentListViewModel
    @State private var showingNewMomentForm = false
    @State private var showingSettings = false
    @State private var selectedMoment: Moment?
    @State private var prefilledDescription: String?
    @State private var prefilledType: String?

    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    init(viewModel: MomentListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.moments.isEmpty {
                    // Initial loading
                    loadingView
                } else if viewModel.moments.isEmpty {
                    // Empty state
                    EmptyStateView(
                        title: "Noch keine Momente heute",
                        message: "Erfasse deinen ersten Moment für heute",
                        actionTitle: "Moment erfassen",
                        action: {
                            showingNewMomentForm = true
                        }
                    )
                } else {
                    // Moments list
                    momentsList
                }
            }
            .navigationTitle("Heute")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                        }
                        .keyboardShortcut(",", modifiers: .command)

                        Button(action: { showingNewMomentForm = true }) {
                            Image(systemName: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 16) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                        }
                        .keyboardShortcut(",", modifiers: .command)

                        Button(action: { showingNewMomentForm = true }) {
                            Image(systemName: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                    }
                }
                #endif
            }
            .refreshable {
                await viewModel.loadTodaysMoments()
            }
            #if os(iOS)
            .onKeyPress(.space) {
                showingNewMomentForm = true
                return .handled
            }
            .onKeyPress("r", phases: .down) { _ in
                Task {
                    await viewModel.loadTodaysMoments()
                }
                return .handled
            }
            #endif
            .task {
                await viewModel.loadTodaysMoments()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMomentForm"))) { notification in
                if let userInfo = notification.userInfo,
                   let description = userInfo["description"] as? String,
                   let type = userInfo["type"] as? String {
                    prefilledDescription = description
                    prefilledType = type
                    showingNewMomentForm = true
                }
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
            .sheet(isPresented: $showingNewMomentForm) {
                newMomentFormSheet
            }
            .sheet(item: $selectedMoment) { moment in
                editMomentFormSheet(moment: moment)
            }
            .sheet(isPresented: $showingSettings) {
                settingsSheet
            }
            .overlay(alignment: .bottom) {
                if viewModel.deletedMoment != nil {
                    UndoToast(message: "Moment gelöscht") {
                        viewModel.cancelDelete()
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.deletedMoment != nil)
                }
            }
        }
    }

    // MARK: - Subviews

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

    private var momentsList: some View {
        List {
            ForEach(viewModel.moments) { moment in
                Button(action: {
                    selectedMoment = moment
                }) {
                    MomentListItemView(
                        moment: moment,
                        project: nil, // TODO: Load project details
                        lifeArea: nil  // TODO: Load life area details
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteMoment(moment)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.deleteMoment(moment)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Sheet Content

    private var newMomentFormSheet: some View {
        // Initialize local AI service if Foundation Models available
        let aiService: GeminiServiceProtocol? = {
            #if canImport(FoundationModels)
            return LocalAIService()
            #else
            return nil
            #endif
        }()

        let formViewModel = MomentFormViewModel(
            apiService: NotionAPIService(),
            modelContext: modelContext,
            geminiService: aiService
        )

        // Pre-fill form data if available from shortcut/deep link
        if let description = prefilledDescription {
            formViewModel.title = description
        }
        if let typeName = prefilledType {
            // Set the type after loading (will be applied in the view's task)
            Task {
                await formViewModel.loadAvailableOptions()
                formViewModel.selectedType = formViewModel.momentTypes.first { $0.name == typeName }
            }
        }

        return MomentFormView(viewModel: formViewModel)
            .onDisappear {
                // Refresh list after form dismissal
                Task {
                    await viewModel.loadTodaysMoments()
                }
                // Clear prefilled data
                prefilledDescription = nil
                prefilledType = nil
            }
    }

    private func editMomentFormSheet(moment: Moment) -> some View {
        // Initialize local AI service if Foundation Models available
        let aiService: GeminiServiceProtocol? = {
            #if canImport(FoundationModels)
            return LocalAIService()
            #else
            return nil
            #endif
        }()

        let formViewModel = MomentFormViewModel(
            apiService: NotionAPIService(),
            modelContext: modelContext,
            geminiService: aiService
        )
        formViewModel.setupForEditing(moment: moment)

        return MomentFormView(viewModel: formViewModel)
            .onDisappear {
                // Refresh list after form dismissal
                Task {
                    await viewModel.loadTodaysMoments()
                }
            }
    }

    private var settingsSheet: some View {
        SettingsView()
    }
}

// MARK: - Previews

#Preview("With Moments") {
    let mockService = NotionAPIService.mock()
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    // Add mock config
    let config = AppConfiguration.mock()
    mockContext.insert(config)

    let viewModel = MomentListViewModel(apiService: mockService, modelContext: mockContext)
    viewModel.moments = [
        Moment.mock(title: "Meeting mit Team", type: .erlebnis),
        Moment.mock(title: "Neue Feature-Idee", type: .idee),
        Moment.mock(title: "Spaziergang im Park", type: .aktivität)
    ]

    return MomentListView(viewModel: viewModel)
        .modelContainer(AppConfiguration.modelContainer)
}

#Preview("Empty State") {
    let mockService = NotionAPIService.mock()
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    let viewModel = MomentListViewModel(apiService: mockService, modelContext: mockContext)

    return MomentListView(viewModel: viewModel)
        .modelContainer(AppConfiguration.modelContainer)
}

#Preview("Loading") {
    let mockService = NotionAPIService.mock()
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    let viewModel = MomentListViewModel(apiService: mockService, modelContext: mockContext)
    viewModel.isLoading = true

    return MomentListView(viewModel: viewModel)
        .modelContainer(AppConfiguration.modelContainer)
}
