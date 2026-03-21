import Foundation

public struct CollectionService {

    @discardableResult
    public static func createCollection(
        name: String,
        notes: String? = nil,
        context: DataContext
    ) throws -> WMCollection {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }
        let collection = WMCollection(name: trimmed, notes: notes)
        context.insert(collection)
        return collection
    }

    public static func renameCollection(
        _ collection: WMCollection,
        to newName: String,
        context: DataContext
    ) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }
        collection.name = trimmed
        try context.save()
    }

    /// Deletes the collection and sets collectionId to nil on all affected projects.
    public static func deleteCollection(_ collection: WMCollection, context: DataContext) throws {
        let collectionId = collection.id
        let affected = context.fetchProjects(where: { $0.collectionId == collectionId })
        for project in affected { project.collectionId = nil }
        context.delete(collection)
        try context.save()
    }
}
