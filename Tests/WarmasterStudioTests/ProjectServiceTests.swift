import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("ProjectService Tests")
struct ProjectServiceTests {

    @MainActor
    func makeContainerAndPipeline() throws -> (ModelContainer, Pipeline) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
            configurations: config
        )
        let pipeline = try PipelineService.bootstrap(context: container.mainContext)
        return (container, pipeline)
    }

    @Test("createProject creates exactly N ModelRecords in first stage")
    @MainActor
    func createProjectCreatesRecords() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let firstStage = pipeline.stages.sorted { $0.position < $1.position }.first!

        let project = try ProjectService.createProject(
            name: "Space Marines", modelCount: 5, in: pipeline, context: context
        )

        #expect(project.modelRecords.count == 5)
        for record in project.modelRecords {
            #expect(record.currentStageId == firstStage.id)
        }
    }

    @Test("createProject with zero count throws invalidModelCount")
    @MainActor
    func createProjectZeroCount() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext

        #expect(throws: WMError.invalidModelCount) {
            try ProjectService.createProject(name: "Bad", modelCount: 0, in: pipeline, context: context)
        }
    }

    @Test("updateProject updates fields")
    @MainActor
    func updateProject() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext

        let project = try ProjectService.createProject(
            name: "Old Name", modelCount: 3, in: pipeline, context: context
        )

        try ProjectService.updateProject(project, name: "New Name", notes: "Updated", context: context)
        #expect(project.name == "New Name")
        #expect(project.notes == "Updated")
    }

    @Test("deleteProject removes project and model records")
    @MainActor
    func deleteProjectCascades() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext

        let project = try ProjectService.createProject(
            name: "To Delete", modelCount: 3, in: pipeline, context: context
        )
        let projectId = project.id

        try ProjectService.deleteProject(project, context: context)

        let projectDescriptor = FetchDescriptor<Project>()
        let projects = try context.fetch(projectDescriptor)
        #expect(!projects.contains { $0.id == projectId })

        let recordDescriptor = FetchDescriptor<ModelRecord>(
            predicate: #Predicate { $0.projectId == projectId }
        )
        let records = try context.fetch(recordDescriptor)
        #expect(records.isEmpty)
    }
}
