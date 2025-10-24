//
//  MomentTypeButton.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI

/// Button for selecting a moment type with vibrant gradients and delightful animations
/// Features glassmorphism, spring animations, and haptic feedback
struct MomentTypeButton: View {
    // MARK: - Properties

    let type: MomentType
    let isSelected: Bool
    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 12) {
                // Gradient Circle with Glassmorphism - Larger Size
                Circle()
                    .fill(ColorMapper.gradientForType(type))
                    .frame(width: 70, height: 70)
                    .shadow(
                        color: type.color.color.opacity(isSelected ? 0.4 : 0.2),
                        radius: isSelected ? 12 : 6,
                        y: isSelected ? 6 : 3
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                .white.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? .white.opacity(0.7) : Color.clear,
                                lineWidth: 3
                            )
                            .animation(
                                reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6),
                                value: isSelected
                            )
                    )
                    .overlay(
                        Text(String(type.name.prefix(1)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                // Type name
                Text(type.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .opacity(isSelected ? 1.0 : 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? .white.opacity(0.3) : .white.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: .black.opacity(isSelected ? 0.15 : 0.08),
                radius: isSelected ? 10 : 5,
                y: isSelected ? 5 : 2
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6),
                value: isPressed
            )
            .animation(
                reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Typ: \(type.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    // MARK: - Actions

    private func handleTap() {
        // Haptic feedback for type selection
        HapticManager.typeSelection()

        // Execute action
        action()
    }
}

// MARK: - Previews

#Preview("Selected") {
    MomentTypeButton(
        type: .gedanke,
        isSelected: true,
        action: {}
    )
    .padding()
    .frame(width: 120)
}

#Preview("Not Selected") {
    MomentTypeButton(
        type: .erlebnis,
        isSelected: false,
        action: {}
    )
    .padding()
    .frame(width: 120)
}

#Preview("All Types Grid") {
    let types: [MomentType] = [.gedanke, .erlebnis, .aktivität, .idee, .emotion, .lernen]

    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(types, id: \.id) { type in
                MomentTypeButton(
                    type: type,
                    isSelected: type.name == "Gedanke",
                    action: {}
                )
            }
        }
        .padding()
    }
}
