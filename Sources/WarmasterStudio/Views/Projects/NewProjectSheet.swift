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
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────────
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Text("New Project")
                    .font(.headline)
                Spacer()
                Button("Create") { createProject() }
                    .disabled(!canCreate)
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
                        TextField("e.g. Space Marine Strike Force", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Model count
                    SheetField(label: "Number of Models") {
                        HStack(spacing: 10) {
                            TextField("", value: $modelCount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                            Stepper("", value: $modelCount, in: 1...200)
                                .labelsHidden()
                        }
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
        .frame(minWidth: 440, idealWidth: 480, minHeight: 380)
    }

    private func createProject() {
        guard let pipeline else { return }
        do {
            let sortedStages = pipeline.stages.sorted { $0.position < $1.position }
            let project = try ProjectService.createProject(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                modelCount: modelCount,
                collectionId: selectedCollectionId,
                notes: notes.isEmpty ? nil : notes,
                in: pipeline,
                context: modelContext
            )
            if let firstStage = sortedStages.first {
                try StageHistoryService.recordCreation(
                    records: project.modelRecords,
                    initialStageId: firstStage.id,
                    initialStageName: firstStage.name,
                    projectId: project.id,
                    collectionId: selectedCollectionId,
                    context: modelContext
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Logger.project.error("Create project failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reusable labelled field wrapper

struct SheetField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            content()
        }
    }
}
