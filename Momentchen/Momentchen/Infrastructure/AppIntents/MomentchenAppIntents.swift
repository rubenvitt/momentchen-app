//
//  MomentchenAppIntents.swift
//  Momentchen
//
//  App Intents for Siri and Shortcuts integration
//

import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct MomentchenShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureMomentIntent(),
            phrases: [
                "Erfasse ein \(.applicationName) Moment",
                "Neues Moment in \(.applicationName)",
                "Speichere ein Moment in \(.applicationName)"
            ],
            shortTitle: "Moment erfassen",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: CaptureThoughtIntent(),
            phrases: [
                "Erfasse einen Gedanken in \(.applicationName)",
                "Neuer Gedanke in \(.applicationName)",
                "Gedanke speichern in \(.applicationName)"
            ],
            shortTitle: "Gedanke erfassen",
            systemImageName: "thought.bubble"
        )

        AppShortcut(
            intent: OpenReviewModeIntent(),
            phrases: [
                "Öffne Review-Modus in \(.applicationName)",
                "Starte Review in \(.applicationName)",
                "Zeige Reviews in \(.applicationName)"
            ],
            shortTitle: "Review-Modus",
            systemImageName: "star.circle.fill"
        )

        AppShortcut(
            intent: ViewTodaysMomentsIntent(),
            phrases: [
                "Zeige heutige Momente in \(.applicationName)",
                "Meine Momente heute in \(.applicationName)",
                "Was ist heute passiert in \(.applicationName)"
            ],
            shortTitle: "Heutige Momente",
            systemImageName: "calendar.badge.clock"
        )
    }
}

// MARK: - Capture Moment Intent

struct CaptureMomentIntent: AppIntent {
    static var title: LocalizedStringResource = "Moment erfassen"
    static var description = IntentDescription("Erfasse einen neuen Moment mit Beschreibung und Typ")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Beschreibung")
    var momentDescription: String

    @Parameter(
        title: "Typ",
        default: "Gedanke"
    )
    var momentType: String

    static var parameterSummary: some ParameterSummary {
        Summary("Erfasse \(\.$momentDescription) als \(\.$momentType)")
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        // Return intent to open the app with deep link
        var intent = OpenMomentFormIntent()
        intent.description = momentDescription
        intent.type = momentType
        return .result(opensIntent: intent)
    }
}

// MARK: - Capture Thought Intent

struct CaptureThoughtIntent: AppIntent {
    static var title: LocalizedStringResource = "Gedanke erfassen"
    static var description = IntentDescription("Erfasse schnell einen Gedanken")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Gedanke")
    var thoughtText: String

    static var parameterSummary: some ParameterSummary {
        Summary("Erfasse Gedanken: \(\.$thoughtText)")
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        // Return intent to open the app with the thought preset as "Gedanke" type
        var intent = OpenMomentFormIntent()
        intent.description = thoughtText
        intent.type = "Gedanke"
        return .result(opensIntent: intent)
    }
}

// MARK: - Open Review Mode Intent

struct OpenReviewModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Review-Modus öffnen"
    static var description = IntentDescription("Öffne den Review-Modus zur Durchsicht deiner Favoriten")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Post notification to switch to review tab
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenReviewMode"),
            object: nil
        )

        return .result()
    }
}

// MARK: - View Today's Moments Intent

struct ViewTodaysMomentsIntent: AppIntent {
    static var title: LocalizedStringResource = "Heutige Momente anzeigen"
    static var description = IntentDescription("Zeige alle Momente von heute")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Post notification to switch to moments tab
        NotificationCenter.default.post(
            name: NSNotification.Name("ViewTodaysMoments"),
            object: nil
        )

        return .result()
    }
}

// MARK: - Open Moment Form Intent (Deep Link)

struct OpenMomentFormIntent: AppIntent {
    static var title: LocalizedStringResource = "Moment-Formular öffnen"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Beschreibung")
    var description: String

    @Parameter(title: "Typ")
    var type: String

    func perform() async throws -> some IntentResult {
        // Post notification with user info to open form with pre-filled data
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenMomentForm"),
            object: nil,
            userInfo: [
                "description": description,
                "type": type
            ]
        )

        return .result()
    }
}
