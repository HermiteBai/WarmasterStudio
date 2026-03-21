import Foundation
import SwiftData
import os

struct CollectionService {

    @discardableResult
    static func createCollection(name: String, notes: String? = nil, context: ModelContext) throws -> WMCollection {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }
        let collection = WMCollection(name: trimmed, notes: notes)
        context.insert(collection)
        try context.save()
        Logger.collection.info("Created collection '\(trimmed)'.")
        return collection
    }

    static func renameCollection(_ collection: WMCollection, to newName: String, context: ModelContext) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }
        collection.name = trimmed
        try context.save()
        Logger.collection.info("Renamed collection to '\(trimmed)'.")
    }

    /// Deletes the collection and sets collectionId to nil on all affected projects.
    static func deleteCollection(_ collection: WMCollection, context: ModelContext) throws {
        let collectionId = collection.id
        Logger.collection.info("Deleting collection '\(collection.name)' (id: \(collectionId)).")

        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.collectionId == collectionId }
        )
        let affectedProjects = try context.fetch(descriptor)
        for project in affectedProjects {
            project.collectionId = nil
        }
        Logger.collection.debug("Unlinked \(affectedProjects.count) project(s) from deleted collection.")

        context.delete(collection)
        try context.save()
    }
}
