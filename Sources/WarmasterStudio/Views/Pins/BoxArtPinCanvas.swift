import SwiftUI
import SwiftData
import os

/// Displays a box-art image with interactive recipe pins overlaid.
/// Supports placing new pins (click in "add pin" mode), popovers,
/// drag-to-reposition, and deletion.
struct BoxArtPinCanvas: View {
    @Environment(\.modelContext) private var modelContext

    let image: NSImage
    let projectId: UUID

    @Query private var allRecipes: [PaintRecipe]
    @Query private var allPins: [RecipePin]

    @State private var addPinMode = false
    @State private var pendingLocation: CGPoint? = nil
    @State private var showRecipePicker = false
    @State private var activePinId: UUID? = nil

    private var projectPins: [RecipePin] {
        allPins.filter { $0.projectId == projectId }
    }

    init(image: NSImage, projectId: UUID) {
        self.image = image
        self.projectId = projectId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Canvas
            GeometryReader { geo in
                let size = geo.size
                ZStack(alignment: .topLeading) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .gesture(addPinMode ? placementGesture(in: size) : nil)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(addPinMode ? Color.wmPrimary : Color.clear, lineWidth: 2)
                        )

                    ForEach(projectPins) { pin in
                        PinView(
                            pin: pin,
                            canvasSize: size,
                            isActive: activePinId == pin.id,
                            allRecipes: allRecipes,
                            onDelete: { deletePin(pin) },
                            onDragEnd: { newNorm in repositionPin(pin, to: newNorm) }
                        )
                    }

                    // Ghost pin while tapping
                    if addPinMode, let loc = pendingLocation {
                        PinDot(color: .wmPrimary.opacity(0.5))
                            .position(x: loc.x, y: loc.y)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
            .aspectRatio(imageAspect, contentMode: .fit)
            .frame(maxHeight: 280)
            .accessibilityLabel("Box art for project with \(projectPins.count) recipe pin\(projectPins.count == 1 ? "" : "s")")

            // Toolbar row
            HStack(spacing: 12) {
                Toggle(isOn: $addPinMode) {
                    Label(addPinMode ? "Placing Pin…" : "Add Pin", systemImage: "pin.fill")
                        .font(.subheadline)
                }
                .toggleStyle(.button)
                .tint(addPinMode ? .wmPrimary : nil)

                if addPinMode {
                    Text("Click the image to place a pin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showRecipePicker) {
            RecipePickerSheet(recipes: allRecipes) { recipe in
                if let loc = pendingLocation {
                    // We stored the raw canvas point; convert back to normalised
                    // using the rendered image frame stored separately is tricky,
                    // so we stored normalised coords in pendingNorm below.
                }
                commitPin(recipe: recipe)
            }
        }
    }

    // MARK: - Gesture

    private func placementGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let norm = normalise(value.location, in: size)
                pendingLocation = value.location
                pendingNorm = norm
                showRecipePicker = true
            }
    }

    @State private var pendingNorm: CGPoint = .zero

    // MARK: - Helpers

    private var imageAspect: CGFloat {
        image.size.width > 0 ? image.size.width / image.size.height : 1
    }

    private func normalise(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: max(0, min(1, point.x / size.width)),
            y: max(0, min(1, point.y / size.height))
        )
    }

    private func commitPin(recipe: PaintRecipe) {
        let pin = RecipePin(
            x: Double(pendingNorm.x),
            y: Double(pendingNorm.y),
            recipeId: recipe.id,
            recipeName: recipe.name,
            projectId: projectId
        )
        modelContext.insert(pin)
        try? modelContext.save()
        pendingLocation = nil
        addPinMode = false
        Logger.paint.info("Placed pin for recipe '\(recipe.name)'")
    }

    private func deletePin(_ pin: RecipePin) {
        modelContext.delete(pin)
        try? modelContext.save()
    }

    private func repositionPin(_ pin: RecipePin, to norm: CGPoint) {
        pin.x = Double(max(0, min(1, norm.x)))
        pin.y = Double(max(0, min(1, norm.y)))
        try? modelContext.save()
    }
}

// MARK: - Pin view

private struct PinView: View {
    @Environment(\.modelContext) private var modelContext

    let pin: RecipePin
    let canvasSize: CGSize
    let isActive: Bool
    let allRecipes: [PaintRecipe]
    let onDelete: () -> Void
    let onDragEnd: (CGPoint) -> Void

    @State private var showPopover = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private var position: CGPoint {
        CGPoint(x: pin.x * canvasSize.width, y: pin.y * canvasSize.height)
    }

    private var displayPosition: CGPoint {
        CGPoint(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
    }

    private var linkedRecipe: PaintRecipe? {
        allRecipes.first { $0.id == pin.recipeId }
    }

    var body: some View {
        PinDot(color: .wmPrimary)
            .position(x: displayPosition.x, y: displayPosition.y)
            .gesture(dragGesture)
            .onTapGesture { showPopover.toggle() }
            .popover(isPresented: $showPopover, arrowEdge: .top) {
                pinPopover
            }
            .accessibilityLabel("Recipe pin: \(pin.recipeName)")
            .accessibilityHint("Double tap to view recipe, drag to reposition")
    }

    @ViewBuilder
    private var pinPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(pin.recipeName, systemImage: "list.bullet.clipboard.fill")
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    showPopover = false
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }

            Divider()

            if let recipe = linkedRecipe {
                let sortedSteps = recipe.steps.sorted { $0.position < $1.position }
                if sortedSteps.isEmpty {
                    Text("No steps yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let first = sortedSteps[0]
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Step 1 — \(first.technique.rawValue)", systemImage: first.technique.systemImage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(first.paintName)
                            .font(.subheadline.bold())
                        if !first.notes.isEmpty {
                            Text(first.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if sortedSteps.count > 1 {
                        Text("+ \(sortedSteps.count - 1) more step\(sortedSteps.count - 1 == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text("Recipe no longer exists.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(minWidth: 220, maxWidth: 300)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                let newX = position.x + value.translation.width
                let newY = position.y + value.translation.height
                dragOffset = .zero
                onDragEnd(CGPoint(
                    x: newX / canvasSize.width,
                    y: newY / canvasSize.height
                ))
            }
    }
}

// MARK: - Pin dot shape

private struct PinDot: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
            Image(systemName: "pin.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Recipe picker sheet

struct RecipePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let recipes: [PaintRecipe]
    let onSelect: (PaintRecipe) -> Void

    @State private var searchText = ""

    private var filtered: [PaintRecipe] {
        if searchText.isEmpty { return recipes.sorted { $0.name < $1.name } }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Create a recipe in the Recipes tab first.")
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filtered) { recipe in
                        Button {
                            onSelect(recipe)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.name)
                                    .foregroundStyle(.primary)
                                Text("\(recipe.steps.count) step\(recipe.steps.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Link Recipe to Pin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(minWidth: 320, minHeight: 380)
    }
}
