import SwiftUI
import SwiftData
import os

struct PaintLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Paint.brand) private var allPaints: [Paint]

    @State private var searchText = ""
    @State private var brandFilter: BrandFilter = .all
    @State private var colorFilter: ColorFamily = .all
    @State private var sortOrder: SortOrder = .nameAscending
    @State private var selectedPaint: Paint?
    @State private var showingAddSheet = false

    enum SortOrder: String, CaseIterable {
        case nameAscending  = "Name (A → Z)"
        case nameDescending = "Name (Z → A)"
        case brand          = "Brand"
        case hex            = "Hex"
        case color          = "Color"

        var systemImage: String {
            switch self {
            case .nameAscending:  return "textformat.abc"
            case .nameDescending: return "textformat.abc"
            case .brand:          return "tag"
            case .hex:            return "number"
            case .color:          return "paintpalette"
            }
        }
    }

    enum BrandFilter: String, CaseIterable {
        case all         = "All"
        case citadel     = "Citadel"
        case vallejo     = "Vallejo"
        case armyPainter = "Army Painter"
        case akInteractive = "AK Interactive"
        case scale75     = "Scale75"
        case reaper      = "Reaper"
        case user        = "User"

        /// Prefix used to match brands (e.g. "Vallejo" matches "Vallejo" and "Vallejo Game Color")
        var brandPrefix: String? {
            switch self {
            case .all:           return nil
            case .citadel:       return "Citadel"
            case .vallejo:       return "Vallejo"
            case .armyPainter:   return "Army Painter"
            case .akInteractive: return "AK Interactive"
            case .scale75:       return "Scale75"
            case .reaper:        return "Reaper"
            case .user:          return nil
            }
        }
    }

    enum ColorFamily: String, CaseIterable {
        case all     = "All"
        case white   = "White"
        case black   = "Black"
        case grey    = "Grey"
        case red     = "Red"
        case orange  = "Orange"
        case yellow  = "Yellow"
        case green   = "Green"
        case teal    = "Teal"
        case blue    = "Blue"
        case purple  = "Purple"
        case pink    = "Pink"
        case brown   = "Brown"
        case metal   = "Metal"

        var displayColor: Color {
            switch self {
            case .all:    return .primary
            case .white:  return Color(hex: "F5F5F5")
            case .black:  return Color(hex: "1C1C1C")
            case .grey:   return Color(hex: "888888")
            case .red:    return Color(hex: "C02020")
            case .orange: return Color(hex: "E07030")
            case .yellow: return Color(hex: "F0C820")
            case .green:  return Color(hex: "3A8830")
            case .teal:   return Color(hex: "208878")
            case .blue:   return Color(hex: "2050A8")
            case .purple: return Color(hex: "6030A0")
            case .pink:   return Color(hex: "D050A0")
            case .brown:  return Color(hex: "7A4828")
            case .metal:  return Color(hex: "A0A8B0")
            }
        }
    }

    private var filteredPaints: [Paint] {
        let filtered = allPaints.filter { paint in
            let matchesBrand: Bool = {
                switch brandFilter {
                case .all:  return true
                case .user: return paint.isUserAdded
                default:
                    guard let prefix = brandFilter.brandPrefix else { return true }
                    return paint.brand.hasPrefix(prefix)
                }
            }()
            let matchesSearch = searchText.isEmpty
                || paint.name.localizedCaseInsensitiveContains(searchText)
                || paint.brand.localizedCaseInsensitiveContains(searchText)
            let matchesColor: Bool = {
                guard colorFilter != .all else { return true }
                return PaintLibraryView.colorFamily(for: paint.hex, name: paint.name) == colorFilter
            }()
            return matchesBrand && matchesSearch && matchesColor
        }
        return filtered.sorted { a, b in
            switch sortOrder {
            case .nameAscending:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .nameDescending:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
            case .brand:
                let brandCmp = a.brand.localizedCaseInsensitiveCompare(b.brand)
                if brandCmp != .orderedSame { return brandCmp == .orderedAscending }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .hex:
                return a.hex.uppercased() < b.hex.uppercased()
            case .color:
                let hueA = PaintLibraryView.hue(from: a.hex) ?? -1
                let hueB = PaintLibraryView.hue(from: b.hex) ?? -1
                return hueA < hueB
            }
        }
    }

    /// Raw hue (0–360) from a 6-char hex string, or nil for achromatic colours.
    private static func hue(from hex: String) -> Double? {
        guard hex.count == 6,
              let rv = UInt8(hex.prefix(2), radix: 16),
              let gv = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
              let bv = UInt8(hex.dropFirst(4), radix: 16) else { return nil }
        let r = Double(rv)/255, g = Double(gv)/255, b = Double(bv)/255
        let cmax = max(r,g,b), cmin = min(r,g,b)
        let delta = cmax - cmin
        guard delta > 0 else { return nil }
        var h: Double
        if cmax == r      { h = 60 * (((g-b)/delta).truncatingRemainder(dividingBy: 6)) }
        else if cmax == g { h = 60 * (((b-r)/delta) + 2) }
        else              { h = 60 * (((r-g)/delta) + 4) }
        return h < 0 ? h + 360 : h
    }

    private static func colorFamily(for hex: String, name: String) -> ColorFamily {
        let lowerName = name.lowercased()
        let metalKeywords = ["silver", "gold", "brass", "bronze", "copper", "iron", "steel",
                             "chrome", "aluminum", "metal", "mithril", "chainmail", "leadbelcher",
                             "runefang", "ironbreaker", "skullcrusher", "retributor", "liberator",
                             "auric", "warplock", "balthasar", "speed metal", "thrash metal"]
        if metalKeywords.contains(where: { lowerName.contains($0) }) { return .metal }

        guard hex.count == 6,
              let rv = UInt8(hex.prefix(2), radix: 16),
              let gv = UInt8(hex.dropFirst(2).prefix(2), radix: 16),
              let bv = UInt8(hex.dropFirst(4), radix: 16) else { return .grey }

        let r = Double(rv) / 255, g = Double(gv) / 255, b = Double(bv) / 255
        let cmax = max(r, g, b), cmin = min(r, g, b)
        let delta = cmax - cmin
        let sat = cmax == 0 ? 0.0 : delta / cmax
        let val = cmax

        if val < 0.18                      { return .black }
        if val > 0.82 && sat < 0.12       { return .white }
        if sat < 0.12                      { return .grey  }

        var hue = 0.0
        if delta > 0 {
            if cmax == r      { hue = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6)) }
            else if cmax == g { hue = 60 * (((b - r) / delta) + 2) }
            else              { hue = 60 * (((r - g) / delta) + 4) }
            if hue < 0 { hue += 360 }
        }

        if hue >= 10 && hue < 45 && sat > 0.25 && val < 0.65 { return .brown }

        switch hue {
        case 0..<15:    return .red
        case 15..<45:   return .orange
        case 45..<70:   return .yellow
        case 70..<155:  return .green   // tightened: ~155° is where green becomes teal
        case 155..<205: return .teal    // picks up blue-greens like Kabalite, Jade
        case 205..<250: return .blue    // pure blues
        case 250..<295: return .purple  // violet/indigo/purple (was incorrectly blue)
        case 295..<345: return .pink
        case 345..<360: return .red
        default:        return .grey
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
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                HStack {
                                    Label(order.rawValue, systemImage: order.systemImage)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.title2)
                            .foregroundStyle(Color.wmPrimary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Sort paints")
                    .accessibilityLabel("Sort paints, current: \(sortOrder.rawValue)")

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
                HStack(spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Menu {
                        ForEach(BrandFilter.allCases, id: \.self) { filter in
                            Button {
                                brandFilter = filter
                            } label: {
                                HStack {
                                    Text(filter.rawValue)
                                    if brandFilter == filter {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(brandFilter.rawValue)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.wmPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.wmSurface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.wmBorder, lineWidth: 1))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .accessibilityLabel("Filter by brand: \(brandFilter.rawValue)")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                // Color family filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ColorFamily.allCases, id: \.self) { family in
                            Button {
                                colorFilter = family
                            } label: {
                                HStack(spacing: 5) {
                                    if family == .all {
                                        Image(systemName: "circle.grid.2x2.fill")
                                            .foregroundStyle(Color.wmPrimary)
                                            .font(.system(size: 12))
                                            .accessibilityHidden(true)
                                    } else {
                                        Circle()
                                            .fill(family.displayColor)
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                                            .accessibilityHidden(true)
                                    }
                                    Text(family.rawValue)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorFilter == family ? Color.wmPrimary.opacity(0.25) : Color.wmSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(colorFilter == family ? Color.wmPrimary : Color.wmBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(family.rawValue) colour filter\(colorFilter == family ? ", selected" : "")")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }

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
                .accessibilityLabel("\(paint.name) colour swatch, \(paint.brand)")
                .accessibilityHidden(true)
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
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(paint.name), \(paint.brand), \(paint.isUserAdded ? "user paint" : "catalogue paint")")
        .accessibilityHint("Double-click to edit")
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
