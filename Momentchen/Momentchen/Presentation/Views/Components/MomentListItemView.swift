//
//  MomentListItemView.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI

/// Reusable list item view for displaying a moment
struct MomentListItemView: View {
    // MARK: - Properties

    let moment: Moment
    let project: Project?
    let lifeArea: LifeArea?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator circle
            Circle()
                .fill(moment.type.color.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(moment.type.color.color, lineWidth: 2)
                )
                .overlay(
                    Text(String(moment.type.name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(moment.type.color.color)
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(moment.title)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Timestamp
                Text(formatTime(moment.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Category badges
                if project != nil || lifeArea != nil {
                    HStack(spacing: 6) {
                        if let project = project {
                            CategoryBadge(
                                icon: "folder.fill",
                                text: project.title,
                                color: .blue
                            )
                        }

                        if let lifeArea = lifeArea {
                            CategoryBadge(
                                icon: "star.fill",
                                text: lifeArea.title,
                                color: .orange
                            )
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(moment.type.name): \(moment.title)")
        .accessibilityHint("Um \(formatTime(moment.timestamp)) Uhr")
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Category Badge

private struct CategoryBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Moment with Project") {
    List {
        MomentListItemView(
            moment: Moment.mock(
                title: "Meeting mit Team erfolgreich abgeschlossen",
                type: .erlebnis
            ),
            project: Project.mock(title: "Momentchen App"),
            lifeArea: nil
        )
    }
}

#Preview("Moment with Life Area") {
    List {
        MomentListItemView(
            moment: Moment.mock(
                title: "Meditation am Morgen",
                type: .aktivität
            ),
            project: nil,
            lifeArea: LifeArea.mock(title: "Gesundheit")
        )
    }
}

#Preview("Moment with Both") {
    List {
        MomentListItemView(
            moment: Moment.mock(
                title: "Neue Feature-Idee: Dark Mode Support",
                type: .idee
            ),
            project: Project.mock(title: "Momentchen App"),
            lifeArea: LifeArea.mock(title: "Karriere")
        )
    }
}
