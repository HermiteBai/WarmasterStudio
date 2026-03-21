import SwiftUI
import SwiftData
import os

struct RecipeStepEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var recipe: PaintRecipe
    var onDone: (() -> Void)? = nil

    // Step add form state
    @State private var paintSearch = ""
    @State private var selectedPaint: Paint?
    @State private var technique: Technique = .basecoat
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showingPaintPicker = false

    @Query(sort: \Paint.brand) private var allPaints: [Paint]

    private var sortedSteps: [RecipeStep] {
        recipe.steps.sorted { $0.position < $1.position }
    }

    private var filteredPaints: [Paint] {
        guard !paintSearch.isEmpty else { return allPaints }
        return allPaints.filter {
            $0.name.localizedCaseInsensitiveContains(paintSearch)
            || $0.brand.localizedCaseInsensitiveContains(paintSearch)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Edit Steps")
                        .font(.title3.bold())
                    Text(recipe.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    onDone?()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.wmPrimary)
            }
            .padding(20)

            Divider().background(Color.wmBorder)

            HSplitView {
                // ── Step list ───────────────────────────────────────────
                VStack(spacing: 0) {
                    Text("Steps")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    if sortedSteps.isEmpty {
                        Spacer()
                        Text("No steps yet.\nAdd one using the form →")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(sortedSteps) { step in
                                StepEditorRowView(step: step) {
                                    deleteStep(step)
                                }
                            }
                            .onMove { fromOffsets, toOffset in
                                reorder(fromOffsets: fromOffsets, toOffset: toOffset)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .frame(minWidth: 200, idealWidth: 240)
                .background(Color.wmSurface)

                // ── Add step form ───────────────────────────────────────
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Step")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        // Paint picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Paint").font(.caption).foregroundStyle(.secondary)
                            Button {
                                showingPaintPicker.toggle()
                            } label: {
                                HStack {
                                    if let paint = selectedPaint {
                                        Circle()
                                            .fill(Color(hex: paint.hex))
                                            .frame(width: 18, height: 18)
                                            .overlay(Circle().strokeBorder(Color.wmBorder, lineWidth: 1))
                                        Text(paint.displayName)
                                            .foregroundStyle(.primary)
                                    } else {
                                        Image(systemName: "eyedropper")
                                            .foregroundStyle(.secondary)
                                        Text("Select a paint…")
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(Color.wmBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.wmBorder))
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $showingPaintPicker) {
                                PaintPickerPopover(
                                    search: $paintSearch,
                                    paints: filteredPaints,
                                    onSelect: { paint in
                                        selectedPaint = paint
                                        showingPaintPicker = false
                                    }
                                )
                            }
                        }

                        // Technique picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Technique").font(.caption).foregroundStyle(.secondary)
                            Picker("Technique", selection: $technique) {
                                ForEach(Technique.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.caption).foregroundStyle(.secondary)
                            TextEditor(text: $notes)
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .background(Color.wmBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.wmBorder))
                                .font(.body)
                        }

                        if let msg = errorMessage {
                            Text(msg).foregroundStyle(.red).font(.caption)
                        }

                        Button("Add Step") {
                            addStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.wmAccent)
                        .disabled(selectedPaint == nil)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                }
                .frame(minWidth: 260)
                .background(Color.wmBackground)
            }
        }
        .frame(width: 580, height: 460)
        .background(Color.wmBackground)
        .preferredColorScheme(.dark)
    }

    private func addStep() {
        guard let paint = selectedPaint else { return }
        do {
            try RecipeService.addStep(
                to: recipe,
                paintId: paint.id,
                paintName: paint.displayName,
                technique: technique,
                notes: notes,
                context: modelContext
            )
            // Reset form
            selectedPaint = nil
            paintSearch = ""
            technique = .basecoat
            notes = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            Logger.recipe.error("Failed to add step: \(error)")
        }
    }

    private func deleteStep(_ step: RecipeStep) {
        do {
            try RecipeService.deleteStep(step, context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            Logger.recipe.error("Failed to delete step: \(error)")
        }
    }

    private func reorder(fromOffsets: IndexSet, toOffset: Int) {
        do {
            try RecipeService.reorderSteps(
                in: recipe,
                fromOffsets: fromOffsets,
                toOffset: toOffset,
                context: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
            Logger.recipe.error("Failed to reorder steps: \(error)")
        }
    }
}

// MARK: - Step editor row

private struct StepEditorRowView: View {
    let step: RecipeStep
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: step.technique.systemImage)
                .foregroundStyle(Color.wmAccent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.paintName)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(step.technique.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Paint picker popover

private struct PaintPickerPopover: View {
    @Binding var search: String
    let paints: [Paint]
    let onSelect: (Paint) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search paints…", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.wmSurface)

            Divider().background(Color.wmBorder)

            if paints.isEmpty {
                Text("No paints found")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(paints) { paint in
                            Button {
                                onSelect(paint)
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color(hex: paint.hex))
                                        .frame(width: 18, height: 18)
                                        .overlay(Circle().strokeBorder(Color.wmBorder, lineWidth: 1))
                                    Text(paint.displayName)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .background(Color.wmBackground.opacity(0.001))
                            Divider().background(Color.wmBorder)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .frame(width: 280)
        .background(Color.wmBackground)
        .preferredColorScheme(.dark)
    }
}
