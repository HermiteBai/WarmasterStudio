import SwiftUI
import SwiftData
import os

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]
    @Query private var projects: [Project]
    @Query(sort: \Stage.position) private var stages: [Stage]

    @State private var showCreateSheet = false
    @State private var renamingCollection: WMCollection? = nil
    @State private var deleteConfirmCollection: WMCollection? = nil
    @State private var selectedProject: Project? = nil
    @State private var expandedCollections: Set<UUID> = []

    private func projectsFor(_ collection: WMCollection) -> [Project] {
        projects.filter { $0.collectionId == collection.id }
            .sorted { $0.name < $1.name }
    }

    private var uncollectedProjects: [Project] {
        projects.filter { $0.collectionId == nil }
            .sorted { $0.name < $1.name }
    }

    private func stageSummary(_ project: Project) -> String {
        let total = project.modelRecords.count
        guard total > 0 else { return "No models" }
        let grouped = Dictionary(grouping: project.modelRecords, by: \.currentStageId)
        let dominant = grouped.max { $0.value.count < $1.value.count }
        let stageName = stages.first { $0.id == dominant?.key }?.name ?? "Unknown"
        return "\(total) model\(total == 1 ? "" : "s") · \(stageName)"
    }

    var body: some View {
        HSplitView {
            // Left: collapsible collection + project list
            List(selection: $selectedProject) {
                ForEach(collections) { collection in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCollections.contains(collection.id) },
                            set: { expanded in
                                if expanded { expandedCollections.insert(collection.id) }
                                else { expandedCollections.remove(collection.id) }
                            }
                        )
                    ) {
                        ForEach(projectsFor(collection)) { project in
                            ProjectRowView(project: project, distribution: stageSummary(project))
                                .tag(project)
                                .padding(.leading, 8)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color.wmPrimary)
                            Text(collection.name)
                                .font(.headline)
                            Spacer()
                            Text("\(projectsFor(collection).count)")
                                .font(.caption.monospacedDigit())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.wmPrimary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Rename") { renamingCollection = collection }
                            Divider()
                            Button("Delete", role: .destructive) { deleteConfirmCollection = collection }
                        }
                    }
                }

                if !uncollectedProjects.isEmpty {
                    DisclosureGroup("Uncollected") {
                        ForEach(uncollectedProjects) { project in
                            ProjectRowView(project: project, distribution: stageSummary(project))
                                .tag(project)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 220)
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreateSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // Right: project detail
            Group {
                if let project = selectedProject {
                    ScrollView {
                        ProjectDetailView(project: project) {
                            selectedProject = nil
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "Select a Project",
                        subtitle: "Choose a project from the list to view details.",
                        systemImage: "folder"
                    )
                }
            }
            .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)
            .background(Color.wmSurface)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCollectionSheet(isPresented: $showCreateSheet)
        }
        .sheet(item: $renamingCollection) { collection in
            RenameCollectionSheet(collection: collection, isPresented: Binding(
                get: { renamingCollection != nil },
                set: { if !$0 { renamingCollection = nil } }
            ))
        }
        .confirmationDialog(
            "Delete \"\(deleteConfirmCollection?.name ?? "")\"?",
            isPresented: Binding(
                get: { deleteConfirmCollection != nil },
                set: { if !$0 { deleteConfirmCollection = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let col = deleteConfirmCollection {
                    do {
                        try CollectionService.deleteCollection(col, context: modelContext)
                    } catch {
                        Logger.collection.error("Delete collection failed: \(error.localizedDescription)")
                    }
                }
                deleteConfirmCollection = nil
            }
            Button("Cancel", role: .cancel) { deleteConfirmCollection = nil }
        } message: {
            Text("Projects in this collection will not be deleted, but will be unlinked.")
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    let distribution: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(project.name)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(distribution)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct CreateCollectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Collection name", text: $name)
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        do {
                            try CollectionService.createCollection(
                                name: name,
                                notes: notes.isEmpty ? nil : notes,
                                context: modelContext
                            )
                            isPresented = false
                        } catch {
                            Logger.collection.error("Create collection failed: \(error.localizedDescription)")
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 380, minHeight: 260)
    }
}

struct RenameCollectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    let collection: WMCollection
    @Binding var isPresented: Bool
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle("Rename Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try CollectionService.renameCollection(collection, to: name, context: modelContext)
                            isPresented = false
                        } catch {
                            Logger.collection.error("Rename failed: \(error.localizedDescription)")
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { name = collection.name }
        .frame(minWidth: 320, minHeight: 160)
    }
}
