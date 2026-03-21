import SwiftUI
import SwiftData
import os

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]
    @Query private var pipelines: [Pipeline]

    @State private var name = ""
    @State private var modelCount = 5
    @State private var selectedCollectionId: UUID? = nil
    @State private var notes = ""
    @State private var errorMessage: String? = nil

    var pipeline: Pipeline? { pipelines.first }
    var canCreate: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pipeline != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                    Stepper("Models: \(modelCount)", value: $modelCount, in: 1...200)
                }

                Section("Collection (optional)") {
                    Picker("Collection", selection: $selectedCollectionId) {
                        Text("None").tag(UUID?.none)
                        ForEach(collections) { col in
                            Text(col.name).tag(Optional(col.id))
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createProject() }
                        .disabled(!canCreate)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }

    private func createProject() {
        guard let pipeline else { return }
        do {
            try ProjectService.createProject(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                modelCount: modelCount,
                collectionId: selectedCollectionId,
                notes: notes.isEmpty ? nil : notes,
                in: pipeline,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Logger.project.error("Create project failed: \(error.localizedDescription)")
        }
    }
}
