import SwiftUI
import SwiftData
import os

struct EditProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]

    let project: Project

    @State private var name: String = ""
    @State private var selectedCollectionId: UUID? = nil
    @State private var notes: String = ""
    @State private var errorMessage: String? = nil

    var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Models")
                        Spacer()
                        Text("\(project.modelCount)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Collection") {
                    Picker("Collection", selection: $selectedCollectionId) {
                        Text("None").tag(UUID?.none)
                        ForEach(collections) { col in
                            Text(col.name).tag(Optional(col.id))
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProject() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            name = project.name
            selectedCollectionId = project.collectionId
            notes = project.notes ?? ""
        }
        .frame(minWidth: 420, minHeight: 360)
    }

    private func saveProject() {
        do {
            try ProjectService.updateProject(
                project,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                collectionId: selectedCollectionId,
                notes: notes.isEmpty ? nil : notes,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Logger.project.error("Update project failed: \(error.localizedDescription)")
        }
    }
}
