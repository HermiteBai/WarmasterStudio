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
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────────
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Text("Edit Project")
                    .font(.headline)
                Spacer()
                Button("Save") { saveProject() }
                    .disabled(!canSave)
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // ── Fields ────────────────────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Name
                    SheetField(label: "Project Name") {
                        TextField("Project name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Model count (read-only)
                    SheetField(label: "Number of Models") {
                        Text("\(project.modelCount)")
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Collection
                    SheetField(label: "Collection") {
                        Picker("", selection: $selectedCollectionId) {
                            Text("None").tag(UUID?.none)
                            ForEach(collections) { col in
                                Text(col.name).tag(Optional(col.id))
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    // Notes
                    SheetField(label: "Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80, maxHeight: 160)
                            .font(.body)
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    }

                    // Error
                    if let err = errorMessage {
                        Label(err, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
                .padding(24)
            }
        }
        .onAppear {
            name = project.name
            selectedCollectionId = project.collectionId
            notes = project.notes ?? ""
        }
        .frame(minWidth: 440, idealWidth: 480, minHeight: 360)
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
