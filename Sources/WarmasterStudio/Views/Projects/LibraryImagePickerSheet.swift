import SwiftUI
import AppKit

/// A searchable, filterable image browser backed by the local warhammer image library.
/// Selecting an image copies it into the BoxArt sandbox and calls `onSelect` with the
/// resulting relative path (suitable for `Project.boxArtImagePath`).
struct LibraryImagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Called with the BoxArt-relative path once an image is successfully imported.
    let onSelect: (String) -> Void

    // MARK: - State

    @State private var allImages: [LibraryImage] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedSystem: String? = nil
    @State private var selectedFaction: String? = nil
    @State private var errorMessage: String? = nil

    // MARK: - Derived

    private var gameSystems: [String] { ImageLibraryService.gameSystems(in: allImages) }

    private var availableFactions: [String] {
        ImageLibraryService.factions(in: allImages, system: selectedSystem)
    }

    private var filtered: [LibraryImage] {
        allImages.filter { img in
            let matchesSystem  = selectedSystem  == nil || img.gameSystem == selectedSystem
            let matchesFaction = selectedFaction == nil || img.faction    == selectedFaction
            let matchesSearch  = searchText.isEmpty
                || img.name.localizedCaseInsensitiveContains(searchText)
                || img.faction.localizedCaseInsensitiveContains(searchText)
            return matchesSystem && matchesFaction && matchesSearch
        }
    }

    // MARK: - Layout

    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 10)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Filter bar ───────────────────────────────────────────────
                filterBar
                Divider()

                // ── Content ──────────────────────────────────────────────────
                if isLoading {
                    ProgressView("Scanning image library…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !ImageLibraryService.libraryExists {
                    libraryNotFoundView
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText.isEmpty ? (selectedFaction ?? selectedSystem ?? "") : searchText)
                } else {
                    imageGrid
                }
            }
            .navigationTitle("Image Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .status) {
                    if !isLoading {
                        Text("\(filtered.count) of \(allImages.count) images")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search by unit name")
        .frame(minWidth: 600, minHeight: 480)
        .task {
            let result = await Task.detached(priority: .userInitiated) {
                ImageLibraryService.scanLibrary()
            }.value
            allImages = result
            isLoading = false
        }
        .alert("Import Failed", isPresented: Binding(get: { errorMessage != nil },
                                                     set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Filter bar

    @ViewBuilder
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Game-system chips
                Text("System:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FilterChip(label: "All", isSelected: selectedSystem == nil) {
                    selectedSystem = nil
                    selectedFaction = nil
                }

                ForEach(gameSystems, id: \.self) { system in
                    FilterChip(label: system, isSelected: selectedSystem == system) {
                        if selectedSystem == system {
                            selectedSystem = nil
                            selectedFaction = nil
                        } else {
                            selectedSystem = system
                            selectedFaction = nil
                        }
                    }
                }

                if let _ = selectedSystem {
                    Divider().frame(height: 20)

                    // Faction chips
                    Text("Faction:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FilterChip(label: "All", isSelected: selectedFaction == nil) {
                        selectedFaction = nil
                    }

                    ForEach(availableFactions, id: \.self) { faction in
                        FilterChip(label: faction, isSelected: selectedFaction == faction) {
                            selectedFaction = selectedFaction == faction ? nil : faction
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.wmSurface)
    }

    // MARK: - Image grid

    private var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filtered) { image in
                    LibraryImageCell(image: image) {
                        importAndSelect(image)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Library not found

    private var libraryNotFoundView: some View {
        ContentUnavailableView {
            Label("Image Library Not Found", systemImage: "folder.badge.questionmark")
        } description: {
            Text("No images were found at:\n\(ImageLibraryService.libraryURL.path)\n\nUpdate the path in Settings → Image Library.")
        }
    }

    // MARK: - Import

    private func importAndSelect(_ image: LibraryImage) {
        do {
            let relativePath = try ImageService.importImage(from: image.url)
            onSelect(relativePath)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Thumbnail cell

private struct LibraryImageCell: View {
    let image: LibraryImage
    let onTap: () -> Void

    @State private var nsImage: NSImage? = nil
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.wmSurface)
                        .frame(height: 100)

                    if let img = nsImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ProgressView()
                            .frame(height: 100)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isHovered ? Color.wmPrimary : Color.wmBorder, lineWidth: isHovered ? 2 : 1)
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isHovered)

                VStack(spacing: 2) {
                    Text(image.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(image.faction)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onAppear {
            // Load thumbnail lazily on a background thread
            let url = image.url
            Task.detached(priority: .background) {
                let loaded = NSImage(contentsOf: url)
                await MainActor.run { nsImage = loaded }
            }
        }
        .accessibilityLabel("\(image.name), \(image.faction), \(image.gameSystem)")
        .accessibilityHint("Double-click to use as box art")
    }
}

// MARK: - Filter chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.wmPrimary.opacity(0.2) : Color.wmSurface)
                .foregroundStyle(isSelected ? Color.wmPrimary : .secondary)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? Color.wmPrimary.opacity(0.6) : Color.wmBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
