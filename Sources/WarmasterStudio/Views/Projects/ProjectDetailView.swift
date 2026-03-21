import SwiftUI
import SwiftData
import os

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]
    @Query(sort: \Project.name) private var allProjects: [Project]

    let project: Project
    var onDelete: (() -> Void)?

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var showLinkSheet = false
    @State private var showImagePicker = false
    @State private var imageErrorMessage: String? = nil

    var collectionName: String? {
        guard let cid = project.collectionId else { return nil }
        return collections.first { $0.id == cid }?.name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                boxArtSection
                Divider()
                stageDistributionSection
                notesSection
                Divider()
                linkedProjectsSection
            }
            .padding(20)
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditProjectSheet(project: project)
        }
        .sheet(isPresented: $showLinkSheet) {
            LinkProjectSheet(project: project)
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    if let old = project.boxArtImagePath { ImageService.deleteImage(relativePath: old) }
                    project.boxArtImagePath = try ImageService.importImage(from: url)
                    try modelContext.save()
                } catch {
                    imageErrorMessage = error.localizedDescription
                    Logger.image.error("Import failed: \(error.localizedDescription)")
                }
            case .failure(let error):
                imageErrorMessage = error.localizedDescription
            }
        }
        .alert("Image Import Failed", isPresented: Binding(
            get: { imageErrorMessage != nil },
            set: { if !$0 { imageErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(imageErrorMessage ?? "")
        }
        .confirmationDialog(
            "Delete \"\(project.name)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Project", role: .destructive) {
                do {
                    try ProjectService.deleteProject(project, context: modelContext)
                    onDelete?()
                } catch {
                    Logger.project.error("Delete project failed: \(error.localizedDescription)")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the project and all its model records.")
        }
    }
}

// MARK: - Sections

extension ProjectDetailView {
    @ViewBuilder
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(project.name)
                .font(.largeTitle.bold())

            if let col = collectionName {
                Label(col, systemImage: "folder.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label("\(project.modelCount) model\(project.modelCount == 1 ? "" : "s")", systemImage: "person.3.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Created \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    var stageDistributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stage Distribution")
                .font(.headline)

            ForEach(stages) { stage in
                let count = project.modelRecords.filter { $0.currentStageId == stage.id }.count
                if count > 0 {
                    HStack {
                        Text(stage.name).font(.subheadline)
                        Spacer()
                        Text("\(count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var notesSection: some View {
        if let notes = project.notes, !notes.isEmpty {
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes").font(.headline)
                Text(notes).font(.body).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    var linkedProjectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Linked Projects").font(.headline)

            if let groupId = project.linkGroupId {
                let linked = allProjects.filter { $0.id != project.id && $0.linkGroupId == groupId }
                if linked.isEmpty {
                    Text("No other projects in this group yet.")
                        .font(.subheadline).foregroundStyle(.tertiary)
                } else {
                    ForEach(linked) { other in
                        HStack(spacing: 6) {
                            Image(systemName: "link").imageScale(.small).foregroundStyle(Color.wmPrimary)
                            Text(other.name).font(.subheadline)
                            Spacer()
                        }
                    }
                }
                HStack(spacing: 12) {
                    Button("Add to Group…") { showLinkSheet = true }.buttonStyle(.borderless)
                    Button("Unlink from Group") {
                        do { try LinkGroupService.unlinkProject(project, context: modelContext) }
                        catch { Logger.project.error("Unlink failed: \(error.localizedDescription)") }
                    }
                    .buttonStyle(.borderless).foregroundStyle(.red)
                }
                .padding(.top, 2)
            } else {
                Text("Not linked to any project.").font(.subheadline).foregroundStyle(.tertiary)
                Button("Link to Project…") { showLinkSheet = true }.buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    var boxArtSection: some View {
        if let path = project.boxArtImagePath, let url = ImageService.resolveImageURL(relativePath: path) {
            VStack(alignment: .leading, spacing: 8) {
                if let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .frame(maxHeight: 260)
                        .accessibilityLabel("Box art for \(project.name)")
                }
                HStack(spacing: 12) {
                    Button("Change Image") { showImagePicker = true }
                        .buttonStyle(.borderless)
                    Button("Remove Image") {
                        ImageService.deleteImage(relativePath: path)
                        project.boxArtImagePath = nil
                        try? modelContext.save()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
        } else {
            Button {
                showImagePicker = true
            } label: {
                Label("Attach Box Art", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.wmSurface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.wmBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

struct LinkProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.name) private var allProjects: [Project]

    let project: Project
    @State private var searchText = ""
    @State private var errorMessage: String? = nil

    private var candidates: [Project] {
        allProjects.filter { candidate in
            guard candidate.id != project.id else { return false }
            if let myGroup = project.linkGroupId, candidate.linkGroupId == myGroup { return false }
            return searchText.isEmpty || candidate.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Other Projects" : "No Results",
                        systemImage: "link.badge.plus",
                        description: Text(searchText.isEmpty
                            ? "Create more projects to link them together."
                            : "No projects match \"\(searchText)\".")
                    )
                } else {
                    List(candidates) { candidate in
                        Button {
                            do {
                                try LinkGroupService.linkProjects(project, candidate, context: modelContext)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                Logger.project.error("Link failed: \(error.localizedDescription)")
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.name)
                                    .foregroundStyle(.primary)
                                if candidate.linkGroupId != nil {
                                    Text("Already in a group — will merge")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search projects")
            .navigationTitle("Link to Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Link Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .frame(minWidth: 340, minHeight: 400)
    }
}
