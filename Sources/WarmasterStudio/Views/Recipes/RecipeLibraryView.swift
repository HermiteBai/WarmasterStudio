import SwiftUI
import SwiftData
import os

struct RecipeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PaintRecipe.createdAt, order: .reverse) private var recipes: [PaintRecipe]

    @State private var selectedRecipe: PaintRecipe?
    @State private var showingNewRecipeSheet = false
    @State private var showingEditSheet = false
    @State private var errorMessage: String?

    var body: some View {
        HSplitView {
            // ── Left pane ──────────────────────────────────────────────
            VStack(spacing: 0) {
                HStack {
                    Text("Recipes")
                        .font(.title2.bold())
                        .foregroundStyle(Color.wmPrimary)
                    Spacer()
                    Button {
                        showingNewRecipeSheet = true
                    } label: {
                        Label("New Recipe", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.wmAccent)
                    .help("Create new recipe")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().background(Color.wmBorder)

                if recipes.isEmpty {
                    Spacer()
                    EmptyStateView(
                        title: "No Recipes Yet",
                        subtitle: "Tap + to create your first paint recipe.",
                        systemImage: "list.bullet.clipboard"
                    )
                    Spacer()
                } else {
                    List(recipes, selection: $selectedRecipe) { recipe in
                        RecipeRowView(recipe: recipe)
                            .tag(recipe)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 220, idealWidth: 260)
            .background(Color.wmBackground)

            // ── Right pane ─────────────────────────────────────────────
            Group {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe, onEdit: {
                        showingEditSheet = true
                    }, onDelete: {
                        deleteRecipe(recipe)
                    })
                } else {
                    EmptyStateView(
                        title: "Select a Recipe",
                        subtitle: "Choose a recipe from the list to view its steps.",
                        systemImage: "list.bullet.clipboard.fill"
                    )
                }
            }
            .frame(minWidth: 320)
            .background(Color.wmBackground)
        }
        .sheet(isPresented: $showingNewRecipeSheet) {
            NewRecipeSheet()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let recipe = selectedRecipe {
                RecipeStepEditorView(recipe: recipe)
            }
        }
    }

    private func deleteRecipe(_ recipe: PaintRecipe) {
        do {
            try RecipeService.deleteRecipe(recipe, context: modelContext)
            selectedRecipe = nil
        } catch {
            errorMessage = error.localizedDescription
            Logger.recipe.error("Failed to delete recipe: \(error)")
        }
    }
}

// MARK: - Row

private struct RecipeRowView: View {
    let recipe: PaintRecipe

    private var sortedSteps: [RecipeStep] {
        recipe.steps.sorted { $0.position < $1.position }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(recipe.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(recipe.steps.count)")
                .font(.caption.bold())
                .foregroundStyle(Color.wmBackground)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.wmPrimary))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recipe.name), \(recipe.steps.count) step\(recipe.steps.count == 1 ? "" : "s")")
    }
}

// MARK: - Detail (read-only)

struct RecipeDetailView: View {
    let recipe: PaintRecipe
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    private var sortedSteps: [RecipeStep] {
        recipe.steps.sorted { $0.position < $1.position }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("\(recipe.steps.count) step\(recipe.steps.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button("Edit Steps") { onEdit() }
                        .buttonStyle(.bordered)
                        .tint(Color.wmPrimary)
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .foregroundStyle(.red)
                    .accessibilityLabel("Delete recipe \(recipe.name)")
                }
            }
            .padding(20)
            .background(Color.wmSurface)

            Divider().background(Color.wmBorder)

            if sortedSteps.isEmpty {
                Spacer()
                EmptyStateView(
                    title: "No Steps",
                    subtitle: "Tap \"Edit Steps\" to add painting steps.",
                    systemImage: "paintbrush"
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                            RecipeStepRowView(step: step, stepNumber: index + 1)
                            if index < sortedSteps.count - 1 {
                                Divider()
                                    .padding(.leading, 56)
                                    .background(Color.wmBorder)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(recipe.name)\" and all its steps.")
        }
    }
}

// MARK: - Step Row (read-only)

struct RecipeStepRowView: View {
    let step: RecipeStep
    let stepNumber: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(stepNumber)")
                .font(.caption.bold())
                .foregroundStyle(Color.wmBackground)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.wmPrimary))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: step.technique.systemImage)
                        .font(.caption)
                        .foregroundStyle(Color.wmAccent)
                        .accessibilityHidden(true)
                    Text(step.technique.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(Color.wmAccent)
                    Spacer()
                }
                Text(step.paintName)
                    .font(.body)
                    .foregroundStyle(.primary)
                if !step.notes.isEmpty {
                    Text(step.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(step.technique.rawValue): \(step.paintName)\(step.notes.isEmpty ? "" : " — \(step.notes)")")
    }
}
