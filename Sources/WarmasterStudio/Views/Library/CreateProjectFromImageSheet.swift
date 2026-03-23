import SwiftUI
import SwiftData
import os

struct CreateProjectFromImageSheet: View {
    let image: LibraryImage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]
    @Query private var pipelines: [Pipeline]

    @State private var name: String
    @State private var modelCount: Int = 1
    @State private var selectedCollectionId: UUID? = nil
    @State private var errorMessage: String? = nil
    @State private var nsImage: NSImage? = nil
    @State private var isCreating = false

    init(image: LibraryImage) {
        self.image = image
        _name = State(initialValue: image.name)
    }

    private var pipeline: Pipeline? { pipelines.first }

    // Find existing collection whose name matches the faction (case-insensitive)
    private var suggestedCollection: WMCollection? {
        collections.first {
            $0.name.localizedCaseInsensitiveCompare(image.faction) == .orderedSame
        }
    }

    var body: some View {
        // Header
        VStack(spacing: 0) {
            HStack {
                Text("Create Project from Image")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wmSurface)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image preview at top
                    if let img = nsImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.wmSurface)
                            .frame(height: 180)
                            .overlay(ProgressView())
                    }

                    // Project name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project Name")
                            .font(.subheadline.weight(.medium))
                        TextField("Project name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Model count
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Number of Models")
                            .font(.subheadline.weight(.medium))
                        HStack(spacing: 10) {
                            TextField("", value: $modelCount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                            Stepper("", value: $modelCount, in: 1...999)
                                .labelsHidden()
                        }
                    }

                    // Collection — shows the auto-matched or blank selection
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Collection")
                            .font(.subheadline.weight(.medium))
                        Picker("Collection", selection: $selectedCollectionId) {
                            Text("None").tag(UUID?.none)
                            ForEach(collections) { col in
                                Text(col.name).tag(Optional(col.id))
                            }
                        }
                        .labelsHidden()

                        // Show hint when faction doesn't match any collection
                        if suggestedCollection == nil {
                            Label("A new collection \"\(image.faction)\" will be created",
                                  systemImage: "plus.circle")
                                .font(.caption)
                                .foregroundStyle(Color.wmPrimary)
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            // Footer
            HStack {
                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create Project") { createProject() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pipeline == nil || isCreating)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.wmSurface)
        }
        .frame(minWidth: 400, minHeight: 480)
        .onAppear {
            // Auto-select matching collection or leave nil (will create)
            selectedCollectionId = suggestedCollection?.id
            // Load image preview
            let url = image.url
            Task.detached(priority: .userInitiated) {
                let loaded = NSImage(contentsOf: url)
                await MainActor.run { nsImage = loaded }
            }
        }
    }

    private func createProject() {
        guard let pipeline else {
            errorMessage = "No pipeline found. Add stages first."
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        isCreating = true

        do {
            // 1. Resolve collection: use selected, or find-or-create by faction name
            let collectionId: UUID?
            if let chosen = selectedCollectionId {
                collectionId = chosen
            } else {
                // Find existing match or create new one
                if let existing = suggestedCollection {
                    collectionId = existing.id
                } else {
                    let newCol = try CollectionService.createCollection(
                        name: image.faction,
                        context: modelContext
                    )
                    collectionId = newCol.id
                }
            }

            // 2. Import image from library URL to app storage
            let relativePath = try ImageService.importImage(from: image.url)

            // 3. Create project
            let project = try ProjectService.createProject(
                name: trimmedName,
                modelCount: modelCount,
                collectionId: collectionId,
                in: pipeline,
                context: modelContext
            )

            // 4. Attach box art
            project.boxArtImagePath = relativePath
            try modelContext.save()

            Logger.project.info("Created project '\(trimmedName)' from library image '\(image.name)'.")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
        }
    }
}
