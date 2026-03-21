import SwiftUI
import SwiftData
import os

struct PaintLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Paint.brand) private var allPaints: [Paint]

    @State private var searchText = ""
    @State private var brandFilter: BrandFilter = .all
    @State private var selectedPaint: Paint?
    @State private var showingAddSheet = false

    enum BrandFilter: String, CaseIterable {
        case all         = "All"
        case citadel     = "Citadel"
        case vallejo     = "Vallejo"
        case armyPainter = "Army Painter"
        case user        = "User"

        var brandName: String? {
            switch self {
            case .all:         return nil
            case .citadel:     return "Citadel"
            case .vallejo:     return "Vallejo"
            case .armyPainter: return "Army Painter"
            case .user:        return nil
            }
        }
    }

    private var filteredPaints: [Paint] {
        allPaints.filter { paint in
            let matchesBrand: Bool = {
                switch brandFilter {
                case .all:         return true
                case .user:        return paint.isUserAdded
                default:           return paint.brand == brandFilter.brandName
                }
            }()
            let matchesSearch = searchText.isEmpty
                || paint.name.localizedCaseInsensitiveContains(searchText)
                || paint.brand.localizedCaseInsensitiveContains(searchText)
            return matchesBrand && matchesSearch
        }
    }

    var body: some View {
        HSplitView {
            // ── Left pane ───────────────────────────────────────────────
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text("Paints")
                        .font(.title2.bold())
                        .foregroundStyle(Color.wmPrimary)
                    Spacer()
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Paint", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.wmAccent)
                    .help("Add custom paint")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search name or brand…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.wmSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                // Brand filter
                Picker("Brand", selection: $brandFilter) {
                    ForEach(BrandFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                Divider()
                    .background(Color.wmBorder)

                // Paint list
                if filteredPaints.isEmpty {
                    Spacer()
                    EmptyStateView(
                        title: "No Paints Found",
                        subtitle: "Try adjusting your search or filters.",
                        systemImage: "eyedropper"
                    )
                    Spacer()
                } else {
                    List(filteredPaints, selection: $selectedPaint) { paint in
                        PaintRowView(paint: paint)
                            .tag(paint)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 240, idealWidth: 280)
            .background(Color.wmBackground)

            // ── Right pane ──────────────────────────────────────────────
            Group {
                if let paint = selectedPaint {
                    PaintDetailView(paint: paint) {
                        selectedPaint = nil
                    }
                } else {
                    EmptyStateView(
                        title: "Select a Paint",
                        subtitle: "Choose a paint from the list to view details.",
                        systemImage: "paintpalette.fill"
                    )
                }
            }
            .frame(minWidth: 300)
            .background(Color.wmBackground)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPaintSheet()
        }
    }
}

// MARK: - Row

private struct PaintRowView: View {
    let paint: Paint

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: paint.hex))
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(Color.wmBorder, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(paint.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(paint.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if paint.isUserAdded {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.wmAccent)
                    .help("Custom paint")
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail

private struct PaintDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var paint: Paint
    let onDelete: () -> Void

    @State private var editName = ""
    @State private var editBrand = ""
    @State private var editHex = ""
    @State private var showingDeleteAlert = false
    @State private var errorMessage: String?

    private var isEditable: Bool { paint.isUserAdded }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header swatch
            HStack(spacing: 16) {
                Circle()
                    .fill(Color(hex: paint.hex))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(Color.wmBorder, lineWidth: 2))
                    .shadow(color: Color(hex: paint.hex).opacity(0.5), radius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(paint.name)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(paint.brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("#\(paint.hex)")
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.wmAccent)
                }
                Spacer()
            }
            .padding(20)
            .background(Color.wmSurface)

            Divider().background(Color.wmBorder)

            if isEditable {
                // Editable form
                Form {
                    Section("Edit Paint") {
                        LabeledContent("Name") {
                            TextField("Name", text: $editName)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledContent("Brand") {
                            TextField("Brand", text: $editBrand)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledContent("Hex Colour") {
                            HStack {
                                TextField("RRGGBB", text: $editHex)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .onChange(of: editHex) { _, new in
                                        editHex = new.uppercased().prefix(6).description
                                    }
                                Circle()
                                    .fill(Color(hex: editHex.count == 6 ? editHex : "888888"))
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().strokeBorder(Color.wmBorder, lineWidth: 1))
                            }
                        }
                    }

                    if let msg = errorMessage {
                        Section {
                            Text(msg)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                    Section {
                        HStack {
                            Button("Save Changes") {
                                saveChanges()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.wmPrimary)
                            .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)

                            Spacer()

                            Button("Delete Paint", role: .destructive) {
                                showingDeleteAlert = true
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
                .formStyle(.grouped)
                .onAppear {
                    editName  = paint.name
                    editBrand = paint.brand
                    editHex   = paint.hex
                }
                .onChange(of: paint.id) { _, _ in
                    editName  = paint.name
                    editBrand = paint.brand
                    editHex   = paint.hex
                }
            } else {
                // Read-only view for catalogue paints
                Form {
                    Section("Paint Details") {
                        LabeledContent("Name",  value: paint.name)
                        LabeledContent("Brand", value: paint.brand)
                        LabeledContent("Hex",   value: "#\(paint.hex)")
                        LabeledContent("Source", value: "Citadel Catalogue")
                    }
                }
                .formStyle(.grouped)
            }

            Spacer()
        }
        .alert("Delete Paint?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deletePaint()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \"\(paint.name)\" from your paint library.")
        }
    }

    private func saveChanges() {
        do {
            try PaintLibraryService.updatePaint(
                paint,
                name: editName.trimmingCharacters(in: .whitespaces),
                brand: editBrand.trimmingCharacters(in: .whitespaces),
                hex: editHex,
                context: modelContext
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            Logger.paint.error("Failed to save paint: \(error)")
        }
    }

    private func deletePaint() {
        do {
            try PaintLibraryService.deletePaint(paint, context: modelContext)
            onDelete()
        } catch {
            errorMessage = error.localizedDescription
            Logger.paint.error("Failed to delete paint: \(error)")
        }
    }
}

// MARK: - Add Paint Sheet

struct AddPaintSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var hex = "FF0000"
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Custom Paint")
                    .font(.title3.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider().background(Color.wmBorder)

            Form {
                Section {
                    LabeledContent("Name") {
                        TextField("e.g. Mephiston Red", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("Brand") {
                        TextField("e.g. Citadel", text: $brand)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("Hex Colour") {
                        HStack {
                            Text("#")
                                .foregroundStyle(.secondary)
                            TextField("RRGGBB", text: $hex)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: hex) { _, new in
                                    hex = new.uppercased().prefix(6).description
                                }
                            Circle()
                                .fill(Color(hex: hex.count == 6 ? hex : "888888"))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().strokeBorder(Color.wmBorder, lineWidth: 1))
                        }
                    }
                }

                if let msg = errorMessage {
                    Section {
                        Text(msg).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .formStyle(.grouped)

            Divider().background(Color.wmBorder)

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Add Paint") { addPaint() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.wmPrimary)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || brand.trimmingCharacters(in: .whitespaces).isEmpty
                              || hex.count != 6)
            }
            .padding(20)
        }
        .frame(width: 420, height: 360)
        .background(Color.wmBackground)
        .preferredColorScheme(.dark)
    }

    private func addPaint() {
        do {
            try PaintLibraryService.addUserPaint(
                name: name.trimmingCharacters(in: .whitespaces),
                brand: brand.trimmingCharacters(in: .whitespaces),
                hex: hex,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
