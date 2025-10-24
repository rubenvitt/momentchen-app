//
//  CategoryPicker.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

import SwiftUI

/// Unified picker for selecting either a Project or Life Area
/// Enforces business rule: A moment can belong to EITHER a project OR a life area, never both
struct CategoryPicker: View {
    @Binding var selectedCategory: MomentCategory
    let projects: [Project]
    let lifeAreas: [LifeArea]

    var body: some View {
        Picker("Kategorie", selection: $selectedCategory) {
            // None option
            Text("Keine Zuordnung")
                .tag(MomentCategory.none)

            // Projects section
            if !projects.isEmpty {
                Section(header: Text("Projekte")) {
                    ForEach(projects) { project in
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(project.title)
                        }
                        .tag(MomentCategory.project(project))
                    }
                }
            }

            // Life Areas section
            if !lifeAreas.isEmpty {
                Section(header: Text("Lebensbereiche")) {
                    ForEach(lifeAreas) { lifeArea in
                        HStack {
                            Image(systemName: "star.fill")
                            Text(lifeArea.title)
                        }
                        .tag(MomentCategory.lifeArea(lifeArea))
                    }
                }
            }
        }
        .pickerStyle(.menu)
        .font(.body)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var category: MomentCategory = .none

    CategoryPicker(
        selectedCategory: $category,
        projects: [
            Project.mock(id: "1", title: "Marathon Training"),
            Project.mock(id: "2", title: "Website Relaunch")
        ],
        lifeAreas: [
            LifeArea.mock(id: "1", title: "Gesundheit"),
            LifeArea.mock(id: "2", title: "Karriere")
        ]
    )
}
#endif
