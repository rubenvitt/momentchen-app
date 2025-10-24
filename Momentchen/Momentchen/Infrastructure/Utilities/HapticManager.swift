//
//  HapticManager.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

#if canImport(UIKit)
import UIKit

/// Centralized haptic feedback manager for iOS
/// Provides consistent haptic patterns across the app
enum HapticManager {
    // MARK: - Haptic Generators

    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Impact Feedback

    /// Trigger light impact haptic (for subtle interactions)
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        switch style {
        case .light:
            impactLight.prepare()
            impactLight.impactOccurred()
        case .medium:
            impactMedium.prepare()
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.prepare()
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.prepare()
            impactLight.impactOccurred(intensity: 0.5)
        case .rigid:
            impactHeavy.prepare()
            impactHeavy.impactOccurred(intensity: 1.0)
        @unknown default:
            impactLight.prepare()
            impactLight.impactOccurred()
        }
    }

    /// Trigger selection haptic (for picker/selection changes)
    static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    /// Trigger notification haptic (for completion/errors)
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }

    // MARK: - Convenience Methods

    /// Haptic for button tap
    static func buttonTap() {
        impact(style: .light)
    }

    /// Haptic for type selection
    static func typeSelection() {
        impact(style: .light)
    }

    /// Haptic for successful save
    static func saveSuccess() {
        notification(type: .success)
    }

    /// Haptic for error
    static func error() {
        notification(type: .error)
    }

    /// Haptic for warning
    static func warning() {
        notification(type: .warning)
    }
}

#elseif canImport(AppKit)
import AppKit

/// Haptic feedback for macOS (currently no-op as macOS has limited haptic support)
enum HapticManager {
    static func impact(style: Int = 0) {
        // macOS haptics are limited to Force Touch trackpad
        // Could use NSHapticFeedbackManager for supported devices
    }

    static func selection() {
        // No-op on macOS
    }

    static func notification(type: Int) {
        // Could use NSSound for audio feedback
    }

    static func buttonTap() {}
    static func typeSelection() {}
    static func saveSuccess() {}
    static func error() {}
    static func warning() {}
}
#endif
