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

    var collectionName: String? {
        guard let cid = project.collectionId else { return nil }
        return collections.first { $0.id == cid }?.name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
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

                Divider()

                // Stage distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stage Distribution")
                        .font(.headline)

                    ForEach(stages) { stage in
                        let count = project.modelRecords.filter { $0.currentStageId == stage.id }.count
                        if count > 0 {
                            HStack {
                                Text(stage.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let notes = project.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("Linked Projects")
                        .font(.headline)

                    if let groupId = project.linkGroupId {
                        let linked = allProjects.filter { $0.id != project.id && $0.linkGroupId == groupId }
                        if linked.isEmpty {
                            Text("No other projects in this group yet.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(linked) { other in
                                HStack(spacing: 6) {
                                    Image(systemName: "link")
                                        .imageScale(.small)
                                        .foregroundStyle(Color.wmPrimary)
                                    Text(other.name)
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            Button("Add to Group…") { showLinkSheet = true }
                                .buttonStyle(.borderless)
                            Button("Unlink from Group") {
                                do {
                                    try LinkGroupService.unlinkProject(project, context: modelContext)
                                } catch {
                                    Logger.project.error("Unlink failed: \(error.localizedDescription)")
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                        }
                        .padding(.top, 2)
                    } else {
                        Text("Not linked to any project.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        Button("Link to Project…") { showLinkSheet = true }
                            .buttonStyle(.borderless)
                    }
                }
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
