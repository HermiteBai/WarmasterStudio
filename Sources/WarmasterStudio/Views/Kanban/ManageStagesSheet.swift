import SwiftUI
import SwiftData
import os

struct ManageStagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query private var pipelines: [Pipeline]

    @State private var editingNames: [UUID: String] = [:]
    @State private var newStageName = ""
    @State private var showAddField = false
    @State private var stageToDelete: Stage? = nil
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String? = nil

    private var pipeline: Pipeline? { pipelines.first }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────────
            HStack {
                Text("Manage Stages")
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

            // ── Stage list ────────────────────────────────────────────────
            List {
                ForEach(stages) { stage in
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                            .imageScale(.small)

                        TextField("Stage name", text: Binding(
                            get: { editingNames[stage.id] ?? stage.name },
                            set: { editingNames[stage.id] = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .onSubmit { commitRename(stage) }

                        Spacer()

                        Button(role: .destructive) {
                            stageToDelete = stage
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                                .imageScale(.small)
                        }
                        .buttonStyle(.plain)
                        .help("Delete stage")
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
            }
            .listStyle(.inset)

            Divider()

            // ── Add stage ─────────────────────────────────────────────────
            if showAddField {
                HStack(spacing: 8) {
                    TextField("New stage name", text: $newStageName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { commitAdd() }

                    Button("Add") { commitAdd() }
                        .disabled(newStageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Cancel") {
                        showAddField = false
                        newStageName = ""
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            } else {
                Button {
                    showAddField = true
                } label: {
                    Label("Add Stage", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(minWidth: 360, minHeight: 300)
        .alert("Cannot Delete Stage", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Delete \"\(stageToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let stage = stageToDelete { deleteStage(stage) }
            }
            Button("Cancel", role: .cancel) { stageToDelete = nil }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: Actions

    private func commitRename(_ stage: Stage) {
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

    private func commitAdd() {
        guard let pipeline else { return }
        let trimmed = newStageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try StageService.addStage(name: trimmed, to: pipeline, context: modelContext)
            newStageName = ""
            showAddField = false
        } catch {
            Logger.stage.error("Add stage failed: \(error.localizedDescription)")
        }
    }

    private func deleteStage(_ stage: Stage) {
        do {
            try StageService.deleteStage(stage, context: modelContext)
        } catch WMError.stageHasModels(stageName: let name) {
            errorMessage = "'\(name)' still has models in it. Move them to another stage first."
        } catch {
            errorMessage = error.localizedDescription
        }
        stageToDelete = nil
    }
}
