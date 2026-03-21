import SwiftUI
import SwiftData
import os

struct PipelineSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query private var pipelines: [Pipeline]

    @State private var editingNames: [UUID: String] = [:]
    @State private var showAddStage = false
    @State private var newStageName = ""
    @State private var stageHasModelsAlert: String? = nil
    @State private var stageToDelete: Stage? = nil
    @State private var showDeleteConfirm = false

    var pipeline: Pipeline? { pipelines.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(stages) { stage in
                    HStack {
                        TextField("Stage name", text: Binding(
                            get: { editingNames[stage.id] ?? stage.name },
                            set: { editingNames[stage.id] = $0 }
                        ), onCommit: {
                            commitRename(stage: stage)
                        })
                        .textFieldStyle(.plain)
                        .onSubmit {
                            commitRename(stage: stage)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onMove { indices, destination in
                    guard let pipeline else { return }
                    var reordered = stages
                    reordered.move(fromOffsets: indices, toOffset: destination)
                    do {
                        try StageService.reorderStages(reordered, in: pipeline, context: modelContext)
                    } catch {
                        Logger.stage.error("Reorder failed: \(error.localizedDescription)")
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        stageToDelete = stages[index]
                        showDeleteConfirm = true
                    }
                }
            }
            .listStyle(.inset)

            Divider()

            if showAddStage {
                HStack {
                    TextField("New stage name", text: $newStageName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { commitAddStage() }
                    Button("Add") { commitAddStage() }
                        .disabled(newStageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Cancel") {
                        showAddStage = false
                        newStageName = ""
                    }
                }
                .padding(8)
            } else {
                Button {
                    showAddStage = true
                } label: {
                    Label("Add Stage", systemImage: "plus")
                }
                .padding(8)
            }
        }
        .frame(minHeight: 300)
        .alert("Cannot Delete Stage", isPresented: Binding(
            get: { stageHasModelsAlert != nil },
            set: { if !$0 { stageHasModelsAlert = nil } }
        )) {
            Button("OK", role: .cancel) { stageHasModelsAlert = nil }
        } message: {
            Text(stageHasModelsAlert ?? "")
        }
        .confirmationDialog(
            "Delete Stage \"\(stageToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let stage = stageToDelete {
                    deleteStage(stage)
                }
            }
            Button("Cancel", role: .cancel) { stageToDelete = nil }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func commitRename(stage: Stage) {
        guard let newName = editingNames[stage.id] else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != stage.name else {
            editingNames.removeValue(forKey: stage.id)
            return
        }
        do {
            try StageService.renameStage(stage, to: trimmed, context: modelContext)
            editingNames.removeValue(forKey: stage.id)
        } catch {
            Logger.stage.error("Rename failed: \(error.localizedDescription)")
        }
    }

    private func commitAddStage() {
        guard let pipeline else { return }
        let trimmed = newStageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try StageService.addStage(name: trimmed, to: pipeline, context: modelContext)
            newStageName = ""
            showAddStage = false
        } catch {
            Logger.stage.error("Add stage failed: \(error.localizedDescription)")
        }
    }

    private func deleteStage(_ stage: Stage) {
        do {
            try StageService.deleteStage(stage, context: modelContext)
        } catch WMError.stageHasModels(stageName: let name) {
            stageHasModelsAlert = "Cannot delete '\(name)': models are currently in this stage. Move them first."
        } catch {
            stageHasModelsAlert = error.localizedDescription
        }
        stageToDelete = nil
    }
}
