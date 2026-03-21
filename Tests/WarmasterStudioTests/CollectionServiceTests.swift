import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("CollectionService Tests")
struct CollectionServiceTests {

    @MainActor
    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
            configurations: config
        )
    }

    @Test("createCollection creates a collection")
    @MainActor
    func createCollection() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let collection = try CollectionService.createCollection(name: "Army Alpha", context: context)
        #expect(collection.name == "Army Alpha")

        let descriptor = FetchDescriptor<WMCollection>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 1)
    }

    @Test("renameCollection updates name")
    @MainActor
    func renameCollection() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let collection = try CollectionService.createCollection(name: "Old", context: context)
        try CollectionService.renameCollection(collection, to: "New", context: context)
        #expect(collection.name == "New")
    }

    @Test("deleteCollection unlinks projects without deleting them")
    @MainActor
    func deleteCollectionUnlinksProjects() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let collection = try CollectionService.createCollection(name: "My Army", context: context)
        let pipeline = try PipelineService.bootstrap(context: context)

        let project = try ProjectService.createProject(
            name: "Project A", modelCount: 2, collectionId: collection.id, in: pipeline, context: context
        )
        #expect(project.collectionId == collection.id)

        try CollectionService.deleteCollection(collection, context: context)

        #expect(project.collectionId == nil)

        let projectDescriptor = FetchDescriptor<Project>()
        let projects = try context.fetch(projectDescriptor)
        #expect(projects.contains { $0.id == project.id })
    }
}
