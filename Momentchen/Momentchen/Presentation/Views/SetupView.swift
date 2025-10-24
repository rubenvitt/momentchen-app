//
//  SetupView.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI
import SwiftData

/// Setup view for initial app configuration
/// Guides user through token validation and database selection
struct SetupView: View {
    // MARK: - Properties

    @State private var viewModel: SetupViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(viewModel: SetupViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.isTokenValid {
                    tokenInputView
                } else {
                    databaseSelectionView
                }
            }
            .navigationTitle(viewModel.isTokenValid ? "Datenbanken auswählen" : "Mit Notion verbinden")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .alert("Setup abgeschlossen!", isPresented: $viewModel.isSetupComplete) {
                Button("Weiter") {
                    dismiss()
                }
            } message: {
                Text("Die Konfiguration wurde erfolgreich gespeichert.")
            }
        }
    }

    // MARK: - Token Input View

    private var tokenInputView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.blue)

                    Text("Verbinde mit Notion")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Gib deinen Integration Token ein, um die App mit deinem Notion Workspace zu verbinden.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                // Token Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notion Token")
                        .font(.headline)

                    SecureField("secret_...", text: $viewModel.notionToken)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                        .accessibilityLabel("Notion Token Eingabefeld")

                    Link("Wie erstelle ich einen Token?", destination: URL(string: "https://developers.notion.com/docs/create-a-notion-integration")!)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)

                // Validate Button
                Button(action: {
                    Task {
                        await viewModel.validateToken()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Validieren")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.notionToken.isEmpty ? Color.gray : Color.blue)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(viewModel.notionToken.isEmpty || viewModel.isLoading)
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    // MARK: - Database Selection View

    private var databaseSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)

                    Text("Token validiert!")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Wähle jetzt deine drei Notion-Datenbanken aus.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Database Pickers
                VStack(spacing: 20) {
                    DatabasePickerSection(
                        title: "Momente Datenbank",
                        icon: "sparkles",
                        selectedDatabase: $viewModel.selectedMomentsDB,
                        databases: viewModel.availableDatabases
                    )

                    DatabasePickerSection(
                        title: "Projekte Datenbank",
                        icon: "folder.fill",
                        selectedDatabase: $viewModel.selectedProjectsDB,
                        databases: viewModel.availableDatabases
                    )

                    DatabasePickerSection(
                        title: "Lebensbereiche Datenbank",
                        icon: "star.fill",
                        selectedDatabase: $viewModel.selectedLifeAreasDB,
                        databases: viewModel.availableDatabases
                    )
                }
                .padding(.horizontal)

                // Save Button
                Button(action: {
                    Task {
                        try? await viewModel.saveConfiguration()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Speichern")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.canSaveConfiguration ? Color.blue : Color.gray)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(!viewModel.canSaveConfiguration || viewModel.isLoading)
                .padding(.horizontal)

                Spacer()
            }
        }
        .task {
            if viewModel.availableDatabases.isEmpty {
                await viewModel.loadDatabases()
            }
        }
    }
}

// MARK: - Database Picker Section

private struct DatabasePickerSection: View {
    let title: String
    let icon: String
    @Binding var selectedDatabase: NotionDatabaseResponse?
    let databases: [NotionDatabaseResponse]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
            }

            Picker(title, selection: $selectedDatabase) {
                Text("Auswählen...")
                    .tag(nil as NotionDatabaseResponse?)

                ForEach(databases.sorted(by: { db1, db2 in
                    let name1 = (db1.title.first?.plainText).flatMap { $0 } ?? db1.id
                    let name2 = (db2.title.first?.plainText).flatMap { $0 } ?? db2.id
                    return name1.localizedCompare(name2) == .orderedAscending
                }), id: \.id) { database in
                    Text((database.title.first?.plainText).flatMap { $0 } ?? database.id)
                        .tag(database as NotionDatabaseResponse?)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    #if os(iOS)
                    .fill(Color(uiColor: .systemGray6))
                    #else
                    .fill(Color.gray.opacity(0.05))
                    #endif
            )
        }
    }
}

// MARK: - Previews

#Preview("Token Input") {
    let mockService = NotionAPIService.mock()
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )
    let viewModel = SetupViewModel(apiService: mockService, modelContext: mockContext)

    return SetupView(viewModel: viewModel)
}

#Preview("Database Selection") {
    let mockService = NotionAPIService.mock()
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )
    let viewModel = SetupViewModel(apiService: mockService, modelContext: mockContext)
    viewModel.isTokenValid = true
    viewModel.availableDatabases = [
        NotionDatabaseResponse.mock(id: "db1", title: "Momente"),
        NotionDatabaseResponse.mock(id: "db2", title: "Projekte"),
        NotionDatabaseResponse.mock(id: "db3", title: "Lebensbereiche")
    ]

    return SetupView(viewModel: viewModel)
}
