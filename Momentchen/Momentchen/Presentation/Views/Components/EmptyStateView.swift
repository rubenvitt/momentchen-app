//
//  EmptyStateView.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI

/// Empty state view for when no moments exist
struct EmptyStateView: View {
    // MARK: - Properties

    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    // MARK: - Initialization

    init(
        title: String = "Noch keine Momente",
        message: String = "Erfasse deinen ersten Moment für heute",
        actionTitle: String? = "Moment erfassen",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Illustration
            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(.tertiary)
                .symbolEffect(.bounce, value: UUID())

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("With Action") {
    EmptyStateView(
        title: "Noch keine Momente",
        message: "Erfasse deinen ersten Moment für heute",
        actionTitle: "Moment erfassen",
        action: { print("Action tapped") }
    )
}

#Preview("Without Action") {
    EmptyStateView(
        title: "Keine Ergebnisse",
        message: "Es wurden keine Momente gefunden",
        actionTitle: nil,
        action: nil
    )
}
