import SwiftUI
import SwiftData
import os

/// Displays a box-art image with interactive recipe pins overlaid.
/// Supports zoom in/out (buttons + pinch gesture), pan via scroll, and
/// pin placement, drag, popover, and delete.
struct BoxArtPinCanvas: View {
    @Environment(\.modelContext) private var modelContext

    let image: NSImage
    let projectId: UUID

    @Query private var allRecipes: [PaintRecipe]
    @Query private var allPins: [RecipePin]

    @State private var addPinMode = false
    @State private var pendingNorm: CGPoint = .zero
    @State private var showRecipePicker = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var gestureBaseZoom: CGFloat = 1.0

    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 8.0
    private let zoomStep: CGFloat = 0.5
    private let canvasMaxH: CGFloat = 300

    private var projectPins: [RecipePin] {
        allPins.filter { $0.projectId == projectId }
    }

    private var imageAspect: CGFloat {
        image.size.width > 0 ? image.size.width / image.size.height : 1
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Canvas: GeometryReader lets us compute the fit-to-frame base size.
            GeometryReader { geo in
                let base = fitSize(in: geo.size)
                let display = CGSize(width: base.width * zoomScale,
                                     height: base.height * zoomScale)
                ScrollView([.horizontal, .vertical],
                           showsIndicators: zoomScale > 1) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: display.width, height: display.height)
                        .overlay(pinLayer(displaySize: display))
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.wmSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(addPinMode ? Color.wmPrimary : Color.clear,
                                      lineWidth: 2)
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { v in
                            zoomScale = clamp(gestureBaseZoom * v,
                                              lo: minZoom, hi: maxZoom)
                        }
                        .onEnded { _ in gestureBaseZoom = zoomScale }
                )
                .accessibilityLabel(
                    "Box art — \(projectPins.count) pin\(projectPins.count == 1 ? "" : "s")"
                )
            }
            .frame(height: canvasMaxH)

            // Controls row
            HStack(spacing: 4) {
                // Zoom out
                Button { stepZoom(by: -zoomStep) } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .disabled(zoomScale <= minZoom)
                .help("Zoom out")
                .accessibilityLabel("Zoom out, currently at \(Int(zoomScale * 100))%")

                // Zoom percentage
                Text("\(Int(zoomScale * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 36, alignment: .center)
                    .accessibilityHidden(true)

                // Zoom in
                Button { stepZoom(by: zoomStep) } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .disabled(zoomScale >= maxZoom)
                .help("Zoom in")
                .accessibilityLabel("Zoom in, currently at \(Int(zoomScale * 100))%")

                // Reset
                Button { resetZoom() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .imageScale(.small)
                }
                .buttonStyle(.borderless)
                .disabled(zoomScale == minZoom)
                .help("Reset zoom")
                .accessibilityLabel("Reset zoom to 100%")

                Divider().frame(height: 16).padding(.horizontal, 4)

                // Pin mode toggle
                Toggle(isOn: $addPinMode) {
                    Label(addPinMode ? "Placing Pin…" : "Add Pin",
                          systemImage: "pin.fill")
                        .font(.subheadline)
                }
                .toggleStyle(.button)
                .tint(addPinMode ? .wmPrimary : nil)

                if addPinMode {
                    Text("Click the image to place a pin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showRecipePicker) {
            RecipePickerSheet(recipes: allRecipes) { recipe in
                commitPin(recipe: recipe)
            }
        }
    }

    // MARK: - Fit size

    /// Returns the largest size that fits `image` aspect-ratio inside
    /// `container`, capped at `canvasMaxH`.
    private func fitSize(in container: CGSize) -> CGSize {
        let w = max(container.width, 1)
        let h = max(container.height, 1)
        let byWidth  = CGSize(width: w, height: w / imageAspect)
        let byHeight = CGSize(width: h * imageAspect, height: h)
        return byWidth.height <= h ? byWidth : byHeight
    }

    // MARK: - Pin layer

    /// The transparent overlay that carries both the tap-to-place gesture
    /// and the individual pin views. Because it's an overlay on the Image
    /// itself, `displaySize` is always the exact rendered image size.
    @ViewBuilder
    private func pinLayer(displaySize: CGSize) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(addPinMode ? placementGesture(in: displaySize) : nil)
                .accessibilityLabel(addPinMode ? "Box art image, tap to place pin" : "")
                .accessibilityHint(addPinMode ? "Tap to place a pin at that location" : "")
                .accessibilityHidden(!addPinMode)

            ForEach(projectPins) { pin in
                PinView(
                    pin: pin,
                    canvasSize: displaySize,
                    allRecipes: allRecipes,
                    onDelete: { deletePin(pin) },
                    onDragEnd: { repositionPin(pin, to: $0) }
                )
            }
        }
    }

    // MARK: - Zoom helpers

    private func stepZoom(by delta: CGFloat) {
        withAnimation(.easeOut(duration: 0.15)) {
            zoomScale = clamp(zoomScale + delta, lo: minZoom, hi: maxZoom)
        }
        gestureBaseZoom = zoomScale
    }

    private func resetZoom() {
        withAnimation(.easeOut(duration: 0.2)) {
            zoomScale = minZoom
        }
        gestureBaseZoom = minZoom
    }

    private func clamp(_ v: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        Swift.max(lo, Swift.min(hi, v))
    }

    // MARK: - Gesture

    private func placementGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { ev in
                pendingNorm = normalise(ev.location, in: size)
                showRecipePicker = true
            }
    }

    private func normalise(_ pt: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: clamp(size.width  > 0 ? pt.x / size.width  : 0, lo: 0, hi: 1),
            y: clamp(size.height > 0 ? pt.y / size.height : 0, lo: 0, hi: 1)
        )
    }

    // MARK: - Data mutations

    private func commitPin(recipe: PaintRecipe) {
        let pin = RecipePin(x: Double(pendingNorm.x),
                            y: Double(pendingNorm.y),
                            recipeId: recipe.id,
                            recipeName: recipe.name,
                            projectId: projectId)
        modelContext.insert(pin)
        try? modelContext.save()
        addPinMode = false
        Logger.paint.info("Placed pin for recipe '\(recipe.name)'")
    }

    private func deletePin(_ pin: RecipePin) {
        modelContext.delete(pin)
        try? modelContext.save()
    }

    private func repositionPin(_ pin: RecipePin, to norm: CGPoint) {
        pin.x = Double(clamp(CGFloat(norm.x), lo: 0, hi: 1))
        pin.y = Double(clamp(CGFloat(norm.y), lo: 0, hi: 1))
        try? modelContext.save()
    }
}

// MARK: - Pin view

private struct PinView: View {
    let pin: RecipePin
    let canvasSize: CGSize
    let allRecipes: [PaintRecipe]
    let onDelete: () -> Void
    let onDragEnd: (CGPoint) -> Void

    @State private var showPopover = false
    @State private var dragOffset: CGSize = .zero

    private var base: CGPoint {
        CGPoint(x: pin.x * canvasSize.width,
                y: pin.y * canvasSize.height)
    }

    private var display: CGPoint {
        CGPoint(x: base.x + dragOffset.width,
                y: base.y + dragOffset.height)
    }

    private var linkedRecipe: PaintRecipe? {
        allRecipes.first { $0.id == pin.recipeId }
    }

    var body: some View {
        PinDot(color: .wmPrimary)
            .position(x: display.x, y: display.y)
            .gesture(dragGesture)
            .onTapGesture { showPopover.toggle() }
            .popover(isPresented: $showPopover, arrowEdge: .top) { pinPopover }
            .accessibilityLabel("Recipe pin: \(pin.recipeName)")
            .accessibilityHint("Click to view recipe, drag to reposition")
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
                    Image(systemName: "trash").foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }

            Divider()

            if let recipe = linkedRecipe {
                let steps = recipe.steps.sorted { $0.position < $1.position }
                if steps.isEmpty {
                    Text("No steps yet.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    let first = steps[0]
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Step 1 — \(first.technique.rawValue)",
                              systemImage: first.technique.systemImage)
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text(first.paintName).font(.subheadline.bold())
                        if !first.notes.isEmpty {
                            Text(first.notes).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if steps.count > 1 {
                        Text("+ \(steps.count - 1) more step\(steps.count - 1 == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text("Recipe no longer exists.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(minWidth: 220, maxWidth: 300)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in dragOffset = v.translation }
            .onEnded { v in
                dragOffset = .zero
                onDragEnd(CGPoint(
                    x: (base.x + v.translation.width)  / max(1, canvasSize.width),
                    y: (base.y + v.translation.height) / max(1, canvasSize.height)
                ))
            }
    }
}

// MARK: - Pin dot

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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let recipes: [PaintRecipe]
    let onSelect: (PaintRecipe) -> Void

    @State private var searchText = ""
    @State private var showNewRecipeForm = false
    @State private var newRecipeName = ""
    @State private var newRecipeError: String? = nil

    private var filtered: [PaintRecipe] {
        let sorted = recipes.sorted { $0.name < $1.name }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty && !showNewRecipeForm {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Use the + button to create your first recipe.")
                    )
                } else if filtered.isEmpty && !showNewRecipeForm {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        if showNewRecipeForm {
                            Section("New Recipe") {
                                HStack(spacing: 8) {
                                    TextField("Recipe name", text: $newRecipeName)
                                        .textFieldStyle(.roundedBorder)
                                        .onSubmit { createAndSelect() }
                                    Button("Create") { createAndSelect() }
                                        .disabled(newRecipeName.trimmingCharacters(in: .whitespaces).isEmpty)
                                    Button("Cancel") {
                                        showNewRecipeForm = false
                                        newRecipeName = ""
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                                if let err = newRecipeError {
                                    Text(err).font(.caption).foregroundStyle(.red)
                                }
                            }
                        }
                        if !filtered.isEmpty {
                            Section(showNewRecipeForm ? "Existing Recipes" : "") {
                                ForEach(filtered) { recipe in
                                    Button {
                                        onSelect(recipe)
                                        dismiss()
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(recipe.name).foregroundStyle(.primary)
                                            Text("\(recipe.steps.count) step\(recipe.steps.count == 1 ? "" : "s")")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Link Recipe to Pin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !showNewRecipeForm {
                        Button {
                            showNewRecipeForm = true
                            newRecipeName = ""
                        } label: {
                            Label("New Recipe", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .frame(minWidth: 320, minHeight: 380)
    }

    private func createAndSelect() {
        let name = newRecipeName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            let recipe = try RecipeService.createRecipe(name: name, projectId: nil,
                                                        context: modelContext)
            onSelect(recipe)
            dismiss()
        } catch {
            newRecipeError = error.localizedDescription
        }
    }
}
