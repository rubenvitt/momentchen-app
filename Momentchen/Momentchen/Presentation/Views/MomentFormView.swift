//
//  MomentFormView.swift
//  Momentchen
//
//  Created by Developer Agent on 22.10.2025.
//

import SwiftUI
import SwiftData

/// Form view for creating and editing moments
/// Features delightful minimalism with Things-style design
/// Progressive disclosure, hero TextField, playful type buttons
struct MomentFormView: View {
    // MARK: - Properties

    @State private var viewModel: MomentFormViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @FocusState private var titleFieldFocused: Bool
    @State private var showParticleEffect = false
    @State private var showDatePicker = false

    // MARK: - Initialization

    init(viewModel: MomentFormViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Platform-Specific Spacing

    private var horizontalPadding: CGFloat {
        #if os(macOS)
        20
        #else
        24
        #endif
    }

    private var mainSpacing: CGFloat {
        #if os(macOS)
        16
        #else
        20
        #endif
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: mainSpacing) {
                    // Hero TextField
                    heroTextField

                    // Type Segmented Control
                    typeSegmentedControl

                    // Time Row
                    timeRow

                    // Category Section (always visible)
                    categorySection
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 24)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
            .navigationTitle(viewModel.isEditing ? "Moment bearbeiten" : "Neuer Moment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }

                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .particleEffect(
                isTriggered: $showParticleEffect,
                colors: viewModel.selectedType.map { [ColorMapper.colorForType($0)] }
            )
            .task {
                await viewModel.loadAvailableOptions()
                if !viewModel.isEditing {
                    titleFieldFocused = true
                }
            }
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Hero TextField

    private var heroTextField: some View {
        TextField("Was war dein Moment?", text: $viewModel.title, axis: .vertical)
            .font(.title3)
            .fontWeight(.regular)
            .lineLimit(5...)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    #if os(iOS)
                    .fill(Color(uiColor: .systemBackground))
                    #else
                    .fill(Color(nsColor: .windowBackgroundColor))
                    #endif
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
            .focused($titleFieldFocused)
            .accessibilityLabel("Moment Beschreibung")
            .onChange(of: viewModel.title) { oldValue, newValue in
                // Trigger AI inference when title changes (with automatic debouncing)
                viewModel.inferTypeFromTitle()
            }
    }

    // MARK: - Type Selection

    private var typeSegmentedControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Typ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if viewModel.isInferringType {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.leading, 4)
                }

                if viewModel.isAiSuggested {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("KI-Vorschlag")
                            .font(.caption2)
                    }
                    .foregroundColor(.purple)
                    .padding(.leading, 4)
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(viewModel.momentTypes, id: \.id) { type in
                    typeChip(for: type)
                }
            }
        }
    }

    private func typeChip(for type: MomentType) -> some View {
        let isSelected = viewModel.selectedType?.id == type.id

        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectType(type)
            }
            HapticManager.buttonTap()
        }) {
            HStack(spacing: 6) {
                // Color indicator circle
                Circle()
                    .fill(ColorMapper.gradientForType(type))
                    .frame(width: 12, height: 12)

                Text(type.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? ColorMapper.colorForType(type).opacity(0.15) : Color.gray.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? ColorMapper.colorForType(type).opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
            .foregroundColor(isSelected ? ColorMapper.colorForType(type) : .secondary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.97)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Time Row

    private var timeRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                // "Jetzt" Button
                Button(action: {
                    viewModel.setToNow()
                    showDatePicker = false
                    HapticManager.buttonTap()
                }) {
                    Label("Jetzt", systemImage: "clock.fill")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.accentColor.opacity(0.1))
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 44)

                // Date Picker Toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDatePicker.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(viewModel.timestamp, style: .date)
                        Text(viewModel.timestamp, style: .time)
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.gray.opacity(0.05))
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )

            // Expanded DatePicker
            if showDatePicker {
                DatePicker(
                    "Zeitpunkt",
                    selection: $viewModel.timestamp,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        #if os(iOS)
                        .fill(Color(uiColor: .systemBackground))
                        #else
                        .fill(Color(nsColor: .windowBackgroundColor))
                        #endif
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Zuordnung")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if viewModel.isInferringCategory {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.leading, 4)
                }
            }

            CategoryPicker(
                selectedCategory: $viewModel.selectedCategory,
                projects: viewModel.projects,
                lifeAreas: viewModel.lifeAreas,
                isAiSuggested: viewModel.isCategoryAiSuggested,
                onCategorySelected: { category in
                    viewModel.selectCategory(category)
                }
            )
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveMoment()
                if viewModel.saveSuccessful {
                    HapticManager.saveSuccess()
                    showParticleEffect = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }) {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("Speichern")
                    .fontWeight(.semibold)
            }
        }
        .keyboardShortcut(.return, modifiers: .command)
        .disabled(!isFormValid || viewModel.isLoading)
    }

    private var isFormValid: Bool {
        !viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty &&
        viewModel.selectedType != nil
    }
}

// MARK: - Previews

#Preview("New Moment") {
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    let _ = {
        let config = AppConfiguration.mock()
        mockContext.insert(config)
    }()

    let viewModel = MomentFormViewModel.mock(modelContext: mockContext)

    return MomentFormView(viewModel: viewModel)
}

#Preview("Edit Moment") {
    let mockContext = try! ModelContext(
        ModelContainer(for: AppConfiguration.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    )

    let _ = {
        let config = AppConfiguration.mock()
        mockContext.insert(config)
    }()

    let viewModel = MomentFormViewModel.mock(modelContext: mockContext)

    let _ = {
        viewModel.setupForEditing(moment: Moment.mock(
            title: "Spaziergang im Park",
            type: .aktivität
        ))
    }()

    return MomentFormView(viewModel: viewModel)
}
