//
//  LocalAIService.swift
//  Momentchen
//
//  AI service for inferring moment properties using Apple's on-device Foundation Models
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
/// Service for AI-powered moment property inference using Apple's on-device LLM
/// Requires iOS 18+ and Apple Intelligence enabled
@MainActor
final class LocalAIService: AIServiceProtocol {
    // MARK: - Properties

    private let session: LanguageModelSession
    private let model: SystemLanguageModel

    // MARK: - Initialization

    /// Initialize LocalAIService with Foundation Models
    init() {
        print("🤖 LocalAIService initialized with Apple Foundation Models")

        // Get the default on-device language model
        self.model = SystemLanguageModel.default

        // Create a session with instructions
        self.session = LanguageModelSession {
            """
            Du bist ein hilfreicher Assistent, der Momente analysiert und kategorisiert.
            Antworte präzise und halte dich genau an die gegebenen Anweisungen.
            Antworte NUR mit dem angeforderten Wert, ohne zusätzliche Erklärungen.
            """
        }
    }

    // MARK: - Availability

    /// Check if Apple Intelligence is available on this device
    var isAvailable: Bool {
        switch model.availability {
        case .available:
            return true
        case .unavailable(.appleIntelligenceNotEnabled):
            print("⚠️ Apple Intelligence must be enabled in Settings")
            return false
        case .unavailable(.deviceNotEligible):
            print("⚠️ Device doesn't support Apple Intelligence")
            return false
        default:
            print("⚠️ Apple Intelligence unavailable")
            return false
        }
    }

    // MARK: - Public Methods

    /// Infers the most appropriate MomentType based on the title
    /// - Parameters:
    ///   - title: The moment description
    ///   - availableTypes: Available moment types to choose from
    /// - Returns: The inferred MomentType or nil if inference fails
    func inferMomentType(from title: String, availableTypes: [MomentType]) async throws -> MomentType? {
        // Check availability first
        guard isAvailable else {
            print("❌ LocalAIService: Apple Intelligence not available")
            return nil
        }

        // Build prompt with available types
        let typeNames = availableTypes.map { $0.name }.joined(separator: ", ")

        let prompt = """
        Analysiere den folgenden Moment und bestimme den passendsten Typ.

        Verfügbare Typen: \(typeNames)

        Moment: "\(title)"

        Regeln:
        - Gedanke: Reflexionen, Überlegungen, mentale Notizen
        - Erlebnis: Ereignisse, Begegnungen, Erfahrungen
        - Aktivität: Physische Handlungen, Tätigkeiten, Sport
        - Idee: Kreative Einfälle, Konzepte, Inspirationen
        - Emotion: Gefühle, emotionale Zustände, Stimmungen
        - Lernen: Erkenntnisse, Wissensaufnahme, Lernmomente

        Antworte NUR mit dem exakten Typnamen aus der Liste, ohne Erklärung.
        """

        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else {
                print("⚠️ LocalAIService: Empty response")
                return nil
            }

            print("🤖 LocalAIService response: \(text)")

            // Find matching type (case-insensitive)
            return availableTypes.first { type in
                type.name.lowercased() == text.lowercased()
            }
        } catch {
            // Log error but don't throw - AI inference is optional
            print("❌ LocalAIService error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Infers the most appropriate category (project or life area) based on title and type
    /// - Parameters:
    ///   - title: The moment description
    ///   - type: The moment type (optional, provides additional context)
    ///   - projects: Available projects
    ///   - lifeAreas: Available life areas
    /// - Returns: The inferred MomentCategory or nil if inference fails
    func inferCategory(from title: String, type: MomentType?, projects: [Project], lifeAreas: [LifeArea]) async throws -> MomentCategory? {
        // Check availability first
        guard isAvailable else {
            print("❌ LocalAIService: Apple Intelligence not available")
            return nil
        }

        // Build list of available categories
        var categoryOptions: [String] = []
        var categoryMap: [String: MomentCategory] = [:]

        // Add projects
        for project in projects {
            let key = "Projekt: \(project.title)"
            categoryOptions.append(key)
            categoryMap[key.lowercased()] = .project(project)
        }

        // Add life areas
        for lifeArea in lifeAreas {
            let key = "Lebensbereich: \(lifeArea.title)"
            categoryOptions.append(key)
            categoryMap[key.lowercased()] = .lifeArea(lifeArea)
        }

        // Add "none" option
        categoryOptions.append("Keine Zuordnung")
        categoryMap["keine zuordnung"] = MomentCategory.none

        guard !categoryOptions.isEmpty else {
            return nil
        }

        let optionsString = categoryOptions.joined(separator: ", ")
        let typeContext = type.map { " (Typ: \($0.name))" } ?? ""

        let prompt = """
        Analysiere den folgenden Moment\(typeContext) und bestimme die passendste Kategorie.

        Verfügbare Kategorien: \(optionsString)

        Moment: "\(title)"

        Regeln:
        - Projekte: Konkrete Vorhaben, zeitlich begrenzte Ziele, spezifische Arbeitsaufgaben
        - Lebensbereiche: Dauerhafte Aspekte des Lebens (Gesundheit, Familie, Karriere, etc.)
        - "Keine Zuordnung" wenn nichts passt oder zu allgemein

        Antworte NUR mit der exakten Kategorie aus der Liste (inkl. "Projekt:" oder "Lebensbereich:" Präfix), ohne Erklärung.
        """

        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespaces).lowercased()

            guard !text.isEmpty else {
                print("⚠️ LocalAIService: Empty category response")
                return nil
            }

            print("🤖 LocalAIService category response: \(text)")

            // Find matching category (case-insensitive)
            for (key, category) in categoryMap {
                if text.contains(key) || key.contains(text) {
                    return category
                }
            }

            return nil
        } catch {
            // Log error but don't throw - AI inference is optional
            print("❌ LocalAIService category inference error: \(error.localizedDescription)")
            return nil
        }
    }
}
#endif // canImport(FoundationModels)

// MARK: - Test Helpers

#if DEBUG
#if canImport(FoundationModels)
extension LocalAIService {
    /// Create a mock LocalAIService for testing
    static func mock() -> LocalAIService {
        LocalAIService()
    }
}
#endif // canImport(FoundationModels)
#endif // DEBUG
