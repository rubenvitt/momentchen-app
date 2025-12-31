//
//  SettingsView.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI
import SwiftData
import UserNotifications

/// Settings view for app configuration
/// Manages theme preference and setup reset
struct SettingsView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme

    @Query private var configurations: [AppConfiguration]
    @Query private var reviewSettings: [ReviewSettings]

    @State private var selectedTheme: ThemePreference = .system
    @State private var showingResetConfirmation = false
    @State private var notificationsEnabled = false
    @State private var dailyNotificationTime = Date()
    @State private var aiCategorySuggestionsEnabled = false
    @State private var localAIAvailable = false

    private var config: AppConfiguration? {
        configurations.first
    }

    private var settings: ReviewSettings? {
        reviewSettings.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Theme Section
                Section {
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(ThemePreference.allCases, id: \.self) { theme in
                            Text(theme.displayName)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTheme) { _, newTheme in
                        saveThemePreference(newTheme)
                    }
                } header: {
                    Text("Darstellung")
                } footer: {
                    Text("Wähle dein bevorzugtes Farbschema für die App.")
                }

                // Review Notifications Section
                Section {
                    Toggle("Benachrichtigungen aktivieren", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            Task {
                                await handleNotificationToggle(enabled)
                            }
                        }

                    if notificationsEnabled {
                        DatePicker(
                            "Tägliche Benachrichtigung",
                            selection: $dailyNotificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: dailyNotificationTime) { _, newTime in
                            Task {
                                await scheduleNotifications(at: newTime)
                            }
                        }
                    }
                } header: {
                    Text("Review-Erinnerungen")
                } footer: {
                    if notificationsEnabled {
                        Text("Du wirst täglich um \(dailyNotificationTime, style: .time) an deinen Review erinnert.")
                    } else {
                        Text("Aktiviere Benachrichtigungen, um an deine Reviews erinnert zu werden.")
                    }
                }

                // Notion Connection Section
                Section {
                    if let config = config {
                        LabeledContent("Status") {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Verbunden")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button(role: .destructive, action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Setup zurücksetzen")
                            }
                        }
                    }
                } header: {
                    Text("Notion-Verbindung")
                } footer: {
                    Text("Setze die Verbindung zurück, um einen neuen Token oder andere Datenbanken auszuwählen.")
                }

                // AI Features Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                            Text("KI-gestützte Typ-Erkennung")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        HStack {
                            if localAIAvailable {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Verfügbar (On-Device)")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Nicht verfügbar")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if localAIAvailable {
                            Divider()

                            Toggle("Kategorien automatisch vorschlagen", isOn: $aiCategorySuggestionsEnabled)
                                .onChange(of: aiCategorySuggestionsEnabled) { _, enabled in
                                    saveCategorySuggestionsToggle(enabled)
                                }

                            Text("Die KI schlägt automatisch passende Projekte oder Lebensbereiche vor.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("KI-Features")
                } footer: {
                    if localAIAvailable {
                        Text("Diese App nutzt Apple's On-Device Intelligence für KI-Features. Alle Daten bleiben auf deinem Gerät und werden privat und sicher verarbeitet.")
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("KI-Features erfordern:")
                            Text("• iOS 18 oder neuer")
                                .font(.caption)
                            Text("• Apple Intelligence aktiviert")
                                .font(.caption)
                            Text("• Kompatibles Gerät (iPhone 15 Pro oder neuer)")
                                .font(.caption)
                        }
                    }
                }

                // About Section
                Section {
                    LabeledContent("Version") {
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Build") {
                        Text(buildNumber)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Über")
                }
            }
            .navigationTitle("Einstellungen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .task {
                loadCurrentTheme()
                checkLocalAIAvailability()
                loadCategorySuggestionsToggle()
                await loadNotificationSettings()
            }
            .confirmationDialog(
                "Setup wirklich zurücksetzen?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Setup zurücksetzen", role: .destructive) {
                    resetSetup()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Diese Aktion löscht deine Notion-Verbindung. Du musst den Setup-Prozess erneut durchlaufen.")
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
    }

    // MARK: - Helper Methods

    private func loadCurrentTheme() {
        if let config = config {
            selectedTheme = config.theme
        }
    }

    private func saveThemePreference(_ theme: ThemePreference) {
        guard let config = config else { return }

        config.theme = theme
        config.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error saving theme preference: \(error)")
        }
    }

    private func checkLocalAIAvailability() {
        #if canImport(FoundationModels)
        let service = LocalAIService()
        localAIAvailable = service.isAvailable
        #else
        localAIAvailable = false
        #endif
    }

    private func loadCategorySuggestionsToggle() {
        if let config = config {
            aiCategorySuggestionsEnabled = config.aiCategorySuggestionsEnabled
        }
    }

    private func saveCategorySuggestionsToggle(_ enabled: Bool) {
        guard let config = config else { return }

        config.aiCategorySuggestionsEnabled = enabled
        config.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error saving category suggestions toggle: \(error)")
        }
    }

    private func resetSetup() {
        guard let config = config else { return }

        modelContext.delete(config)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error resetting setup: \(error)")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Notification Methods

    private func loadNotificationSettings() async {
        let notificationManager = NotificationManager()
        let status = await notificationManager.checkAuthorizationStatus()

        await MainActor.run {
            notificationsEnabled = (status == .authorized)

            // Load or create settings
            if let existingSettings = settings {
                dailyNotificationTime = existingSettings.dailyNotificationTime
            } else {
                // Create default settings
                let newSettings = ReviewSettings()
                modelContext.insert(newSettings)
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving ReviewSettings: \(error)")
                }
                dailyNotificationTime = newSettings.dailyNotificationTime
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) async {
        let notificationManager = NotificationManager()

        if enabled {
            // Request authorization
            if let granted = try? await notificationManager.requestAuthorization(), granted {
                await scheduleNotifications(at: dailyNotificationTime)
            } else {
                // Authorization denied, turn toggle back off
                await MainActor.run {
                    notificationsEnabled = false
                }
            }
        } else {
            // Cancel all notifications
            await notificationManager.cancelAllReviewNotifications()
        }
    }

    private func scheduleNotifications(at time: Date) async {
        guard notificationsEnabled else { return }

        let notificationManager = NotificationManager()
        let settings = self.settings ?? ReviewSettings()

        // Extract time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        do {
            try await notificationManager.scheduleAllReviewNotifications(
                dailyTime: components,
                weeklyDay: settings.weeklyNotificationDay,
                monthlyDay: settings.monthlyNotificationDay,
                yearlyMonth: settings.yearlyNotificationMonth,
                yearlyDay: settings.yearlyNotificationDay
            )
        } catch {
            print("Error scheduling notifications: \(error)")
        }
    }
}

// MARK: - Previews

#Preview("With Configuration") {
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    // Add mock config
    let config = AppConfiguration.mock()
    mockContext.insert(config)

    return SettingsView()
        .modelContainer(for: AppConfiguration.self, inMemory: true)
        .environment(\.modelContext, mockContext)
}

#Preview("Dark Mode") {
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    // Add mock config with dark theme
    let config = AppConfiguration.mock(theme: .dark)
    mockContext.insert(config)

    return SettingsView()
        .modelContainer(for: AppConfiguration.self, inMemory: true)
        .environment(\.modelContext, mockContext)
        .preferredColorScheme(.dark)
}
