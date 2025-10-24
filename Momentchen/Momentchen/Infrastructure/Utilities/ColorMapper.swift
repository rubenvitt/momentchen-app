//
//  ColorMapper.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI

/// Utility for mapping NotionColor to SwiftUI Color
/// Provides consistent color scheme across the app
enum ColorMapper {
    // MARK: - Color Mapping

    /// Map NotionColor to SwiftUI Color
    /// - Parameter notionColor: Notion color name
    /// - Returns: Corresponding SwiftUI Color
    static func toSwiftUIColor(_ notionColor: NotionColor) -> Color {
        notionColor.color
    }

    /// Map NotionColor to background tint (lighter shade)
    /// - Parameter notionColor: Notion color name
    /// - Returns: Light tinted color suitable for backgrounds
    static func toBackgroundTint(_ notionColor: NotionColor) -> Color {
        notionColor.backgroundTint
    }

    // MARK: - Color Palette

    /// Get all available Notion colors
    /// - Returns: Array of all NotionColor cases
    static var allColors: [NotionColor] {
        NotionColor.allCases
    }

    /// Get color for moment type display
    /// - Parameter type: MomentType with associated color
    /// - Returns: SwiftUI Color for the type
    static func colorForType(_ type: MomentType) -> Color {
        type.color.color
    }

    /// Get background color for moment type
    /// - Parameter type: MomentType with associated color
    /// - Returns: Light tinted background color
    static func backgroundForType(_ type: MomentType) -> Color {
        type.color.backgroundTint
    }

    // MARK: - Gradient Support

    /// Get vibrant gradient for a NotionColor
    /// - Parameter notionColor: Notion color name
    /// - Returns: LinearGradient with light to dark progression
    static func gradientForColor(_ notionColor: NotionColor) -> LinearGradient {
        let (lightColor, darkColor) = gradientColors(for: notionColor)
        return LinearGradient(
            colors: [lightColor, darkColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Get vibrant gradient for a MomentType
    /// - Parameter type: MomentType with associated color
    /// - Returns: LinearGradient matching the type's color theme
    static func gradientForType(_ type: MomentType) -> LinearGradient {
        gradientForColor(type.color)
    }

    /// Get gradient color pair for a NotionColor
    /// - Parameter notionColor: Notion color name
    /// - Returns: Tuple of (light, dark) colors for gradient
    private static func gradientColors(for notionColor: NotionColor) -> (Color, Color) {
        switch notionColor {
        case .blue:
            // Gedanke: Light blue → Deep blue
            return (Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.0, green: 0.3, blue: 0.8))
        case .green:
            // Erlebnis: Light green → Forest green
            return (Color(red: 0.4, green: 0.9, blue: 0.5), Color(red: 0.0, green: 0.5, blue: 0.2))
        case .orange:
            // Aktivität: Light orange → Deep orange
            return (Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.9, green: 0.4, blue: 0.0))
        case .yellow:
            // Idee: Light yellow → Golden yellow
            return (Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.0))
        case .pink:
            // Emotion: Light pink → Deep pink
            return (Color(red: 1.0, green: 0.6, blue: 0.8), Color(red: 0.9, green: 0.2, blue: 0.6))
        case .purple:
            // Lernen: Light purple → Deep purple
            return (Color(red: 0.7, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.1, blue: 0.8))
        case .red:
            return (Color(red: 1.0, green: 0.5, blue: 0.5), Color(red: 0.8, green: 0.1, blue: 0.1))
        case .brown:
            return (Color(red: 0.7, green: 0.5, blue: 0.3), Color(red: 0.4, green: 0.2, blue: 0.1))
        case .gray:
            return (Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.4, green: 0.4, blue: 0.4))
        case .default:
            return (Color.primary.opacity(0.3), Color.primary.opacity(0.6))
        }
    }
}

// MARK: - Color Extensions

extension Color {
    /// Create Color from hex string
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    /// - Returns: SwiftUI Color
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }

        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // RGBA (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Get hex string representation
    /// - Returns: Hex string like "#FF0000"
    var hexString: String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "#000000"
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Theme Support (Platform-Specific)

#if canImport(UIKit)
import UIKit

extension ColorMapper {
    /// Adaptive colors that change based on light/dark mode
    static var adaptiveBackground: Color {
        Color(uiColor: .systemBackground)
    }

    static var adaptiveSecondaryBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    static var adaptiveTertiaryBackground: Color {
        Color(uiColor: .tertiarySystemBackground)
    }

    static var adaptiveLabel: Color {
        Color(uiColor: .label)
    }

    static var adaptiveSecondaryLabel: Color {
        Color(uiColor: .secondaryLabel)
    }
}
#elseif canImport(AppKit)
import AppKit

// macOS compatibility extensions
extension Color {
    init(uiColor: NSColor) {
        self.init(nsColor: uiColor)
    }
}

extension ColorMapper {
    /// Adaptive colors that change based on light/dark mode
    static var adaptiveBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }

    static var adaptiveSecondaryBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    static var adaptiveTertiaryBackground: Color {
        Color(nsColor: .controlColor)
    }

    static var adaptiveLabel: Color {
        Color(nsColor: .labelColor)
    }

    static var adaptiveSecondaryLabel: Color {
        Color(nsColor: .secondaryLabelColor)
    }
}
#endif
