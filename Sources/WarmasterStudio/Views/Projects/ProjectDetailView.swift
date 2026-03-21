import SwiftUI
import SwiftData
import os

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]

    let project: Project
    var onDelete: (() -> Void)?

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

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

                if let groupId = project.linkGroupId {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Link Group")
                            .font(.headline)
                        Text(groupId.uuidString)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
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
