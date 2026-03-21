import SwiftUI
import SwiftData
import os

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]
    @Query private var projects: [Project]

    @State private var showCreateSheet = false
    @State private var newCollectionName = ""
    @State private var newCollectionNotes = ""
    @State private var renamingCollection: WMCollection? = nil
    @State private var renameText = ""
    @State private var deleteConfirmCollection: WMCollection? = nil

    var body: some View {
        List {
            ForEach(collections) { collection in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(collection.name)
                            .font(.headline)
                        let count = projects.filter { $0.collectionId == collection.id }.count
                        Text("\(count) project\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contextMenu {
                    Button("Rename") {
                        renamingCollection = collection
                        renameText = collection.name
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        deleteConfirmCollection = collection
                    }
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
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
