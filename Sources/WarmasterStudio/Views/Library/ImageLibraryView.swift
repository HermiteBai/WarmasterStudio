import SwiftUI
import AppKit

// MARK: - Image Library View

/// Full-window image library browser.
/// Layout:
///   ┌─────────────────────────────────────────────────────┐
///   │  [System Tab] [System Tab] [System Tab] …           │  ← system strip
///   │  [Faction chip] [Faction chip] …                    │  ← faction strip (context)
///   ├─────────────────────────────────────────────────────┤
///   │                                                     │
///   │   □ □ □ □ □ □ □ □ □ □ □ □   ← adaptive grid       │
///   │   □ □ □ □ □ □ □ □ □ □ □ □                          │
///   │                                                     │
///   └─────────────────────────────────────────────────────┘
struct ImageLibraryView: View {

    // MARK: State

    @State private var allImages: [LibraryImage] = []
    @State private var isLoading = true
    @State private var selectedSystem: String? = nil
    @State private var selectedFaction: String? = nil
    @State private var searchText = ""
    @State private var showAddImages = false
    @State private var showNewFactionSheet = false
    @State private var showNewSystemSheet = false
    @State private var errorMessage: String? = nil
    @State private var columnCount: Int = 6          // adapts to window width
    @State private var lightboxImage: LibraryImage? = nil
    @State private var createProjectImage: LibraryImage? = nil
    @StateObject private var downloader = ImageDownloadService()

    // MARK: Computed

    private var gameSystems: [String] { ImageLibraryService.gameSystems(in: allImages) }

    private var availableFactions: [String] {
        ImageLibraryService.factions(in: allImages, system: selectedSystem)
    }

    private var gridImages: [LibraryImage] {
        allImages.filter { img in
            let sys  = selectedSystem  == nil || img.gameSystem == selectedSystem
            let fac  = selectedFaction == nil || img.faction    == selectedFaction
            let srch = searchText.isEmpty
                || img.name.localizedCaseInsensitiveContains(searchText)
                || img.faction.localizedCaseInsensitiveContains(searchText)
                || img.gameSystem.localizedCaseInsensitiveContains(searchText)
            return sys && fac && srch
        }
    }

    private var importTarget: (system: String, faction: String) {
        (system:  selectedSystem  ?? gameSystems.first ?? "Warhammer 40,000",
         faction: selectedFaction ?? availableFactions.first ?? "Uncategorised")
    }

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── System tabs ───────────────────────────────────────────
                systemStrip
                Divider()

                // ── Faction chips (only when a system is selected) ────────
                if selectedSystem != nil && !availableFactions.isEmpty {
                    factionStrip
                    Divider()
                }

                // ── Breadcrumb + count ────────────────────────────────────
                breadcrumbBar

                // ── Main grid ─────────────────────────────────────────────
                if isLoading {
                    Spacer()
                    ProgressView("Scanning image library…")
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else if !ImageLibraryService.libraryExists {
                    libraryMissingView
                } else if gridImages.isEmpty {
                    Spacer()
                    ContentUnavailableView.search(text: searchText.isEmpty
                        ? (selectedFaction ?? selectedSystem ?? "")
                        : searchText)
                    Spacer()
                } else {
                    imageGrid(availableWidth: geo.size.width)
                }
            }
        }
        .background(Color.wmBackground)
        .searchable(text: $searchText, prompt: "Search by unit, faction or system")
        .toolbar { toolbarItems }
        .task { await reload() }
        // Sheets
        .sheet(isPresented: $showNewSystemSheet) {
            NewFolderSheet(
                title: "New Game System",
                prompt: "e.g. Warhammer: The Old World",
                existingNames: gameSystems
            ) { name in await createFolder(system: name, faction: nil) }
        }
        .sheet(isPresented: $showNewFactionSheet) {
            NewFolderSheet(
                title: "New Faction in \"\(selectedSystem ?? "")\"",
                prompt: "e.g. Space Marines",
                existingNames: availableFactions
            ) { name in await createFolder(system: importTarget.system, faction: name) }
        }
        .fileImporter(
            isPresented: $showAddImages,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            let target = importTarget
            Task { await handleImport(result: result, system: target.system, faction: target.faction) }
        }
        .alert("Error", isPresented: Binding(
            get:  { errorMessage != nil },
            set:  { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
        .sheet(isPresented: Binding(
            get: { downloader.isDownloading || {
                if case .finished = downloader.state { return true }
                return false
            }() },
            set: { if !$0 { downloader.reset() } }
        )) {
            DownloadProgressSheet(downloader: downloader)
        }
        .onChange(of: downloader.state) { _, new in
            if case .finished = new { Task { await reload() } }
        }
        .overlay {
            if let image = lightboxImage {
                ZStack {
                    // Dim backdrop — tap outside the panel to dismiss
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { lightboxImage = nil }

                    // Lightbox panel — taps here stay inside
                    ImageLightboxView(image: image, allImages: gridImages) { lightboxImage = nil }
                        .frame(maxWidth: 960, maxHeight: 720)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 32)
                        .onTapGesture { } // absorb taps so they don't reach the backdrop
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: lightboxImage?.id)
            }
        }
        .sheet(item: $createProjectImage) { image in
            CreateProjectFromImageSheet(image: image)
        }
    }

    // MARK: - System strip

    private var systemStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                SystemTab(label: "All", icon: "photo.stack",
                          count: allImages.count,
                          isSelected: selectedSystem == nil) {
                    selectedSystem = nil; selectedFaction = nil
                }
                ForEach(gameSystems, id: \.self) { system in
                    let count = allImages.filter { $0.gameSystem == system }.count
                    SystemTab(label: system, icon: systemIcon(system),
                              count: count,
                              isSelected: selectedSystem == system) {
                        if selectedSystem == system { selectedSystem = nil; selectedFaction = nil }
                        else { selectedSystem = system; selectedFaction = nil }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.wmSurface)
    }

    // MARK: - Faction strip

    private var factionStrip: some View {
        WrapLayout(spacing: 6) {
            FactionChip(label: "All factions",
                        count: allImages.filter { $0.gameSystem == selectedSystem }.count,
                        isSelected: selectedFaction == nil) {
                selectedFaction = nil
            }
            ForEach(availableFactions, id: \.self) { faction in
                let count = allImages.filter {
                    $0.gameSystem == selectedSystem && $0.faction == faction
                }.count
                FactionChip(label: faction, count: count,
                            isSelected: selectedFaction == faction) {
                    selectedFaction = selectedFaction == faction ? nil : faction
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.wmBackground)
    }

    // MARK: - Breadcrumb

    private var breadcrumbBar: some View {
        HStack(spacing: 6) {
            // Path
            Group {
                Text("Library").foregroundStyle(selectedSystem == nil ? .primary : .secondary)
                if let sys = selectedSystem {
                    Image(systemName: "chevron.right").imageScale(.small).foregroundStyle(.tertiary)
                    Text(sys).foregroundStyle(selectedFaction == nil ? .primary : .secondary)
                }
                if let fac = selectedFaction {
                    Image(systemName: "chevron.right").imageScale(.small).foregroundStyle(.tertiary)
                    Text(fac).foregroundStyle(.primary)
                }
            }
            .font(.subheadline)

            Spacer()

            // Count
            if !isLoading {
                Text("\(gridImages.count) image\(gridImages.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.wmBackground)
    }

    // MARK: - Image grid

    private func imageGrid(availableWidth: CGFloat) -> some View {
        let minCell: CGFloat = 160
        let maxCell: CGFloat = 220
        let spacing: CGFloat = 12
        let padding: CGFloat = 20
        let cols = max(2, Int((availableWidth - padding * 2 + spacing) / (minCell + spacing)))
        let cellW = min(maxCell, (availableWidth - padding * 2 - CGFloat(cols - 1) * spacing) / CGFloat(cols))

        return ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellW), spacing: spacing), count: cols),
                spacing: spacing
            ) {
                ForEach(gridImages) { image in
                    LibraryManageCell(image: image, cellWidth: cellW,
                                      allImages: allImages,
                                      onOpen: { lightboxImage = image },
                                      onCreateProject: { createProjectImage = image },
                                      onMove: { system, faction in moveImage(image, toSystem: system, toFaction: faction) },
                                      onDelete: { deleteImage(image) })
                }
            }
            .padding(padding)
            .animation(.easeInOut(duration: 0.2), value: gridImages.count)
        }
    }

    // MARK: - Library missing

    private var libraryMissingView: some View {
        ContentUnavailableView {
            Label("Image Library Empty", systemImage: "photo.stack")
        } description: {
            VStack(spacing: 12) {
                Text("No images found. Download the default library or add your own images using the toolbar.")
                    .multilineTextAlignment(.center)
                Button {
                    downloader.downloadAll()
                } label: {
                    Label("Download Default Library", systemImage: "arrow.down.circle.fill")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .disabled(downloader.isDownloading)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                downloader.downloadAll()
            } label: {
                Label("Download Default Library", systemImage: "arrow.down.circle")
            }
            .help("Download all default images from Games Workshop CDN")
            .disabled(downloader.isDownloading)

            Button {
                showNewSystemSheet = true
            } label: {
                Label("New Game System", systemImage: "plus.rectangle.on.folder")
            }
            .help("Create a new game system folder")

            Button {
                guard selectedSystem != nil else { showNewSystemSheet = true; return }
                showNewFactionSheet = true
            } label: {
                Label("New Faction", systemImage: "folder.badge.plus")
            }
            .help(selectedSystem == nil
                  ? "Select a game system first, then add a faction"
                  : "Add a faction folder in \"\(selectedSystem!)\"")

            Button {
                showAddImages = true
            } label: {
                Label("Add Images…", systemImage: "photo.badge.plus")
            }
            .help("Import images into \"\(importTarget.system) › \(importTarget.faction)\"")
        }
    }

    // MARK: - Actions

    @MainActor private func reload() async {
        isLoading = true
        let result = await Task.detached(priority: .userInitiated) {
            ImageLibraryService.scanLibrary()
        }.value
        allImages = result
        isLoading = false
    }

    private func createFolder(system: String, faction: String?) async {
        let root = ImageLibraryService.libraryURL
        var dir = root.appendingPathComponent(system, isDirectory: true)
        if let f = faction { dir = dir.appendingPathComponent(f, isDirectory: true) }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            await reload()
            selectedSystem = system
            if let f = faction { selectedFaction = f }
        } catch { errorMessage = error.localizedDescription }
    }

    @MainActor
    private func handleImport(result: Result<[URL], Error>, system: String, faction: String) async {
        switch result {
        case .failure(let err): errorMessage = err.localizedDescription
        case .success(let urls):
            let dir = ImageLibraryService.libraryURL
                .appendingPathComponent(system, isDirectory: true)
                .appendingPathComponent(faction, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                for url in urls {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    let dest = dir.appendingPathComponent(url.lastPathComponent)
                    if !FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.copyItem(at: url, to: dest)
                    }
                }
                await reload()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func deleteImage(_ image: LibraryImage) {
        try? FileManager.default.removeItem(at: image.url)
        allImages.removeAll { $0.id == image.id }
    }

    private func moveImage(_ image: LibraryImage, toSystem: String, toFaction: String) {
        guard !(image.gameSystem == toSystem && image.faction == toFaction) else { return }
        let destDir = ImageLibraryService.libraryURL
            .appendingPathComponent(toSystem, isDirectory: true)
            .appendingPathComponent(toFaction, isDirectory: true)
        var dest = destDir.appendingPathComponent(image.url.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            // Avoid overwriting an existing file with the same name
            if FileManager.default.fileExists(atPath: dest.path) {
                let stem = image.url.deletingPathExtension().lastPathComponent
                let ext  = image.url.pathExtension
                dest = destDir.appendingPathComponent("\(stem)_moved.\(ext)")
            }
            try FileManager.default.moveItem(at: image.url, to: dest)
            Task { await reload() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func systemIcon(_ system: String) -> String {
        let s = system.lowercased()
        if s.contains("40") || s.contains("warhammer 4") { return "shield.lefthalf.filled" }
        if s.contains("age") || s.contains("sigmar")     { return "flame.fill" }
        if s.contains("horus") || s.contains("heresy")   { return "bolt.shield.fill" }
        if s.contains("old world") || s.contains("fantasy") { return "map.fill" }
        if s.contains("middle") || s.contains("earth")   { return "mountain.2.fill" }
        return "folder.fill"
    }
}

// MARK: - System tab button

private struct SystemTab: View {
    let label: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.wmPrimary : .secondary)
                Text(label)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.wmPrimary : .secondary)
                    .lineLimit(1)
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.wmPrimary.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.wmPrimary.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(count) images")
    }
}

// MARK: - Faction chip

private struct FactionChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        Capsule().fill(isSelected
                            ? Color.wmPrimary.opacity(0.25)
                            : Color.wmBorder.opacity(0.5))
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isSelected ? Color.wmPrimary : .secondary)
            .background(
                Capsule().fill(isSelected ? Color.wmPrimary.opacity(0.12) : Color.wmSurface)
            )
            .overlay(
                Capsule().strokeBorder(isSelected
                    ? Color.wmPrimary.opacity(0.5) : Color.wmBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thumbnail cell

private struct LibraryManageCell: View {
    let image: LibraryImage
    let cellWidth: CGFloat
    let allImages: [LibraryImage]
    let onOpen: () -> Void
    let onCreateProject: () -> Void
    let onMove: (String, String) -> Void
    let onDelete: () -> Void

    // Grouped factions for the "Move to" context menu
    private var systemsWithFactions: [(system: String, factions: [String])] {
        let systems = Array(Set(allImages.map(\.gameSystem))).sorted()
        return systems.map { sys in
            let factions = Array(Set(allImages.filter { $0.gameSystem == sys }.map(\.faction))).sorted()
            return (system: sys, factions: factions)
        }
    }

    @State private var nsImage: NSImage? = nil
    @State private var isHovered = false
    @State private var showDeleteConfirm = false

    private var thumbHeight: CGFloat { cellWidth * 0.72 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .top) {
                // Thumbnail — tap to open lightbox
                Button(action: onOpen) {
                    Group {
                        if let img = nsImage {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.wmSurface
                                .overlay(Image(systemName: "photo")
                                    .foregroundStyle(.tertiary).font(.title2))
                        }
                    }
                    .frame(width: cellWidth, height: thumbHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isHovered ? Color.wmPrimary.opacity(0.6) : Color.wmBorder,
                                          lineWidth: isHovered ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .help("Click to view full size")

                // Action buttons on hover
                if isHovered {
                    HStack(spacing: 4) {
                        // Create project button (top-left)
                        Button(action: onCreateProject) {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 20))
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Create Project from Image")

                        Spacer()

                        // Delete button (top-right)
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 20))
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Delete from Library")
                    }
                    .padding(5)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeOut(duration: 0.15), value: isHovered)

            // Labels
            VStack(spacing: 2) {
                Text(image.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: cellWidth)
                Text(image.faction)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contextMenu {
            Button { onOpen() } label: {
                Label("Open Full Size", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            Button { onCreateProject() } label: {
                Label("Create Project from Image", systemImage: "plus.circle")
            }
            Divider()
            // Move to faction submenu — nested by game system
            Menu {
                ForEach(systemsWithFactions, id: \.system) { entry in
                    if systemsWithFactions.count > 1 {
                        // Multiple game systems: show system as a sub-menu label
                        Section(entry.system) {
                            ForEach(entry.factions, id: \.self) { faction in
                                Button(faction) { onMove(entry.system, faction) }
                                    .disabled(entry.system == image.gameSystem && faction == image.faction)
                            }
                        }
                    } else {
                        // Single game system: flat list of factions
                        ForEach(entry.factions, id: \.self) { faction in
                            Button(faction) { onMove(entry.system, faction) }
                                .disabled(entry.system == image.gameSystem && faction == image.faction)
                        }
                    }
                }
            } label: {
                Label("Move to Faction", systemImage: "folder.badge.arrow.right")
            }
            Divider()
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label("Delete from Library", systemImage: "trash")
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
            Text("This will permanently remove the image from the library folder.")
        }
        .accessibilityLabel("\(image.name), \(image.faction), \(image.gameSystem)")
    }
}

// MARK: - Lightbox / full-size viewer

/// Full-size image viewer sheet with prev/next navigation and metadata overlay.
struct ImageLightboxView: View {
    let image: LibraryImage
    let allImages: [LibraryImage]
    let onClose: () -> Void

    @State private var currentIndex: Int = 0
    @State private var nsImage: NSImage? = nil
    @State private var isLoadingImage = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0

    private var currentImage: LibraryImage { allImages[currentIndex] }
    private var hasPrev: Bool { currentIndex > 0 }
    private var hasNext: Bool { currentIndex < allImages.count - 1 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Image
            if let img = nsImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(zoomScale * magnifyBy)
                    .offset(dragOffset)
                    .gesture(magnificationGesture)
                    .gesture(dragGesture)
                    .onTapGesture(count: 2) { resetZoom() }
                    .animation(.interactiveSpring(), value: zoomScale)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }

            // Navigation arrows
            HStack {
                navButton(systemImage: "chevron.left", enabled: hasPrev) { navigate(-1) }
                Spacer()
                navButton(systemImage: "chevron.right", enabled: hasNext) { navigate(1) }
            }
            .padding(.horizontal, 16)

            // Top bar: close + zoom controls
            VStack {
                HStack(alignment: .center) {
                    // Image counter
                    Text("\(currentIndex + 1) / \(allImages.count)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial.opacity(0.6), in: Capsule())

                    Spacer()

                    // Zoom controls
                    HStack(spacing: 4) {
                        Button { adjustZoom(-0.25) } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .disabled(zoomScale <= 0.5)

                        Text("\(Int(zoomScale * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 40)

                        Button { adjustZoom(0.25) } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .disabled(zoomScale >= 5.0)

                        Button { resetZoom() } label: {
                            Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    // Close
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(.horizontal, 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Bottom metadata bar
                VStack(spacing: 4) {
                    Text(currentImage.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        Text(currentImage.gameSystem)
                        Text("›")
                        Text(currentImage.faction)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial.opacity(0.7))
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            currentIndex = allImages.firstIndex(where: { $0.id == image.id }) ?? 0
            loadCurrentImage()
        }
        .onKeyPress(.leftArrow)  { navigate(-1); return .handled }
        .onKeyPress(.rightArrow) { navigate(1);  return .handled }
    }

    // MARK: Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in state = value }
            .onEnded { value in
                zoomScale = min(5.0, max(0.5, zoomScale * value))
                dragOffset = .zero
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoomScale > 1 else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard zoomScale > 1 else { dragOffset = .zero; return }
                dragOffset = value.translation
            }
    }

    // MARK: Actions

    private func navigate(_ delta: Int) {
        let next = currentIndex + delta
        guard next >= 0 && next < allImages.count else { return }
        currentIndex = next
        resetZoom()
        loadCurrentImage()
    }

    private func adjustZoom(_ delta: CGFloat) {
        zoomScale = min(5.0, max(0.5, zoomScale + delta))
    }

    private func resetZoom() {
        zoomScale = 1.0
        dragOffset = .zero
    }

    private func loadCurrentImage() {
        nsImage = nil
        isLoadingImage = true
        let url = currentImage.url
        Task.detached(priority: .userInitiated) {
            let img = NSImage(contentsOf: url)
            await MainActor.run {
                nsImage = img
                isLoadingImage = false
            }
        }
    }

    // MARK: Sub-views

    @ViewBuilder
    private func navButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(enabled ? .white : .white.opacity(0.2))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial.opacity(enabled ? 0.5 : 0.2), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - New folder sheet

private struct NewFolderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let prompt: String
    let existingNames: [String]
    let onCreate: (String) async -> Void

    @State private var name = ""

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var isDuplicate: Bool {
        existingNames.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    }
    private var isValid: Bool { !trimmed.isEmpty && !isDuplicate }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            TextField(prompt, text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { if isValid { submit() } }
            if isDuplicate {
                Label("A folder with this name already exists.", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Create") { submit() }
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 340)
    }

    private func submit() {
        guard isValid else { return }
        dismiss()
        Task { await onCreate(trimmed) }
    }
}

// MARK: - Download progress sheet

private struct DownloadProgressSheet: View {
    @ObservedObject var downloader: ImageDownloadService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            switch downloader.state {
            case .downloading(let completed, let total, let currentName):
                VStack(spacing: 12) {
                    Text("Downloading Image Library")
                        .font(.headline)
                    ProgressView(value: Double(completed), total: Double(max(total, 1)))
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 360)
                    Text("\(completed) / \(total)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(currentName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 360)
                }

            case .finished(let downloaded, let skipped):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Download Complete")
                        .font(.headline)
                    Text("\(downloaded) image\(downloaded == 1 ? "" : "s") downloaded, \(skipped) skipped.")
                        .foregroundStyle(.secondary)
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }

            default:
                EmptyView()
            }
        }
        .padding(32)
        .frame(minWidth: 420)
    }
}

// MARK: - WrapLayout

/// A simple flow layout that wraps child views into multiple rows.
private struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > width, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(view)
            rowWidth += size.width + spacing
        }

        let totalHeight = rows.reduce(0.0) { h, row in
            h + (row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0) + spacing
        }
        return CGSize(width: width, height: max(0, totalHeight - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        let maxW = bounds.width

        for view in subviews {
            let w = view.sizeThatFits(.unspecified).width
            if rowWidth + w > maxW, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(view)
            rowWidth += w + spacing
        }

        var y = bounds.minY
        for row in rows {
            let rowH = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowH + spacing
        }
    }
}
