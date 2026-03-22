import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Top-level view

struct ImageLibraryView: View {
    @State private var allImages: [LibraryImage] = []
    @State private var isLoading = true
    @State private var selectedSystem: String? = nil
    @State private var selectedFaction: String? = nil
    @State private var searchText = ""
    @State private var showAddImages = false
    @State private var showNewFactionSheet = false
    @State private var showNewSystemSheet = false
    @State private var errorMessage: String? = nil
    @State private var importDestination: ImportDestination? = nil

    struct ImportDestination {
        let system: String
        let faction: String
    }

    // MARK: Tree data

    private var tree: [(system: String, factions: [(faction: String, count: Int)])] {
        let systems = ImageLibraryService.gameSystems(in: allImages)
        return systems.map { system in
            let factions = ImageLibraryService.factions(in: allImages, system: system).map { faction in
                let count = allImages.filter { $0.gameSystem == system && $0.faction == faction }.count
                return (faction: faction, count: count)
            }
            return (system: system, factions: factions)
        }
    }

    private var gridImages: [LibraryImage] {
        allImages.filter { img in
            let matchSystem  = selectedSystem  == nil || img.gameSystem == selectedSystem
            let matchFaction = selectedFaction == nil || img.faction    == selectedFaction
            let matchSearch  = searchText.isEmpty
                || img.name.localizedCaseInsensitiveContains(searchText)
                || img.faction.localizedCaseInsensitiveContains(searchText)
            return matchSystem && matchFaction && matchSearch
        }
    }

    var body: some View {
        HSplitView {
            // ── Left: system/faction tree ─────────────────────────────────
            libraryTree
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)

            // ── Right: image grid ─────────────────────────────────────────
            imageGridPanel
                .frame(minWidth: 400)
        }
        .toolbar { toolbarItems }
        .searchable(text: $searchText, prompt: "Search images")
        .task { await reload() }
        .sheet(isPresented: $showNewFactionSheet) {
            NewFolderSheet(
                title: "New Faction",
                placeholder: "e.g. Space Marines",
                existingNames: tree.first(where: { $0.system == selectedSystem })?.factions.map(\.faction) ?? []
            ) { name in
                await createFolder(system: selectedSystem ?? "Warhammer 40,000", faction: name)
            }
        }
        .sheet(isPresented: $showNewSystemSheet) {
            NewFolderSheet(
                title: "New Game System",
                placeholder: "e.g. Warhammer: The Old World",
                existingNames: tree.map(\.system)
            ) { name in
                await createFolder(system: name, faction: nil)
            }
        }
        .fileImporter(
            isPresented: $showAddImages,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            guard let dest = importDestination else { return }
            Task { await handleImport(result: result, into: dest) }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    // MARK: - Sidebar tree

    private var libraryTree: some View {
        List(selection: $selectedFaction) {
            if isLoading {
                ProgressView().padding()
            } else if !ImageLibraryService.libraryExists {
                Text("Library not found")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding()
            } else {
                // "All" row
                Label {
                    HStack {
                        Text("All Images")
                        Spacer()
                        Text("\(allImages.count)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } icon: {
                    Image(systemName: "photo.stack")
                }
                .tag(Optional<String>.none)
                .onTapGesture {
                    selectedSystem = nil
                    selectedFaction = nil
                }

                Divider()

                ForEach(tree, id: \.system) { node in
                    Section {
                        ForEach(node.factions, id: \.faction) { factionNode in
                            HStack {
                                Label(factionNode.faction, systemImage: "folder")
                                    .lineLimit(1)
                                Spacer()
                                Text("\(factionNode.count)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .tag(Optional(factionNode.faction))
                            .onTapGesture {
                                selectedSystem = node.system
                                selectedFaction = factionNode.faction
                            }
                            .contextMenu {
                                Button {
                                    importDestination = ImportDestination(
                                        system: node.system,
                                        faction: factionNode.faction
                                    )
                                    showAddImages = true
                                } label: {
                                    Label("Add Images Here…", systemImage: "plus")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(node.system)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(node.factions.reduce(0) { $0 + $1.count })")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .onTapGesture {
                            selectedSystem = node.system
                            selectedFaction = nil
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Image grid panel

    @ViewBuilder
    private var imageGridPanel: some View {
        if isLoading {
            ProgressView("Scanning library…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !ImageLibraryService.libraryExists {
            libraryMissingView
        } else if gridImages.isEmpty {
            ContentUnavailableView.search(text: searchText.isEmpty
                ? (selectedFaction ?? selectedSystem ?? "")
                : searchText)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)],
                          spacing: 12) {
                    ForEach(gridImages) { image in
                        LibraryManageCell(image: image, onDelete: { deleteImage(image) })
                    }
                }
                .padding(16)
            }
            .background(Color.wmBackground)
        }
    }

    // MARK: - Library missing

    private var libraryMissingView: some View {
        ContentUnavailableView {
            Label("Image Library Not Found", systemImage: "folder.badge.questionmark")
        } description: {
            VStack(spacing: 8) {
                Text("Expected library at:")
                Text(ImageLibraryService.libraryURL.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("Update the path in Settings, or create the folder structure manually.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showNewSystemSheet = true
            } label: {
                Label("New Game System", systemImage: "plus.rectangle.on.folder")
            }
            .help("Add a new game system folder")

            Button {
                guard selectedSystem != nil || !tree.isEmpty else {
                    showNewSystemSheet = true
                    return
                }
                showNewFactionSheet = true
            } label: {
                Label("New Faction", systemImage: "folder.badge.plus")
            }
            .help("Add a new faction folder in the selected game system")
            .disabled(selectedSystem == nil && tree.isEmpty)

            Divider()

            Button {
                importDestination = ImportDestination(
                    system: selectedSystem ?? tree.first?.system ?? "Warhammer 40,000",
                    faction: selectedFaction
                        ?? tree.first(where: { $0.system == selectedSystem })?.factions.first?.faction
                        ?? "Uncategorised"
                )
                showAddImages = true
            } label: {
                Label("Add Images…", systemImage: "photo.badge.plus")
            }
            .help("Import image files into the selected faction")
        }

        ToolbarItem(placement: .status) {
            if !isLoading {
                Text("\(gridImages.count) image\(gridImages.count == 1 ? "" : "s")"
                     + (selectedFaction != nil || selectedSystem != nil ? " shown" : " total"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func reload() async {
        isLoading = true
        let result = await Task.detached(priority: .userInitiated) {
            ImageLibraryService.scanLibrary()
        }.value
        allImages = result
        isLoading = false
    }

    private func createFolder(system: String, faction: String?) async {
        let root = ImageLibraryService.libraryURL
        let dir: URL = faction == nil
            ? root.appendingPathComponent(system, isDirectory: true)
            : root.appendingPathComponent(system, isDirectory: true)
                   .appendingPathComponent(faction!, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            await reload()
            selectedSystem = system
            if let f = faction { selectedFaction = f }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func handleImport(result: Result<[URL], Error>, into dest: ImportDestination) async {
        switch result {
        case .failure(let err):
            errorMessage = err.localizedDescription
        case .success(let urls):
            let targetDir = ImageLibraryService.libraryURL
                .appendingPathComponent(dest.system, isDirectory: true)
                .appendingPathComponent(dest.faction, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: targetDir,
                                                        withIntermediateDirectories: true)
                for url in urls {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    let dest = targetDir.appendingPathComponent(url.lastPathComponent)
                    if !FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.copyItem(at: url, to: dest)
                    }
                }
                await reload()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteImage(_ image: LibraryImage) {
        do {
            try FileManager.default.removeItem(at: image.url)
            allImages.removeAll { $0.id == image.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Grid cell with delete

private struct LibraryManageCell: View {
    let image: LibraryImage
    let onDelete: () -> Void

    @State private var nsImage: NSImage? = nil
    @State private var isHovered = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let img = nsImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.wmSurface.overlay(ProgressView())
                    }
                }
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.wmBorder, lineWidth: 1)
                )

                if isHovered {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.title3)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.15), value: isHovered)

            VStack(spacing: 2) {
                Text(image.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(image.faction)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .onHover { isHovered = $0 }
        .onAppear {
            let url = image.url
            Task.detached(priority: .background) {
                let loaded = NSImage(contentsOf: url)
                await MainActor.run { nsImage = loaded }
            }
        }
        .confirmationDialog(
            "Delete \"\(image.name)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the image from the library.")
        }
        .accessibilityLabel("\(image.name), \(image.faction)")
    }
}

// MARK: - New folder sheet

private struct NewFolderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let placeholder: String
    let existingNames: [String]
    let onCreate: (String) async -> Void

    @State private var name = ""

    private var isDuplicate: Bool {
        existingNames.contains(where: { $0.localizedCaseInsensitiveCompare(name.trimmingCharacters(in: .whitespaces)) == .orderedSame })
    }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isDuplicate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)

            TextField(placeholder, text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { if isValid { submit() } }

            if isDuplicate {
                Text("A folder with this name already exists.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Create") { submit() }
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dismiss()
        Task { await onCreate(trimmed) }
    }
}
