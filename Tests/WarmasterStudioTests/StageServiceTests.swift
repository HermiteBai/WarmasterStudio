import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("StageService Tests")
struct StageServiceTests {

    @MainActor
    func makeContainerAndPipeline() throws -> (ModelContainer, Pipeline) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
            configurations: config
        )
        let context = container.mainContext
        let pipeline = try PipelineService.bootstrap(context: context)
        return (container, pipeline)
    }

    @Test("addStage appends a new stage")
    @MainActor
    func addStage() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let initialCount = pipeline.stages.count

        let stage = try StageService.addStage(name: "Varnished", to: pipeline, context: context)
        #expect(pipeline.stages.count == initialCount + 1)
        #expect(stage.name == "Varnished")
    }

    @Test("renameStage updates name")
    @MainActor
    func renameStage() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let stage = pipeline.stages.first!
        let newName = "Ready to Paint"

        try StageService.renameStage(stage, to: newName, context: context)
        #expect(stage.name == newName)
    }

    @Test("renameStage throws on empty name")
    @MainActor
    func renameStageEmptyName() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let stage = pipeline.stages.first!

        #expect(throws: WMError.emptyName) {
            try StageService.renameStage(stage, to: "   ", context: context)
        }
    }

    @Test("reorderStages updates positions")
    @MainActor
    func reorderStages() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let reversed = pipeline.stages.sorted { $0.position > $1.position }

        try StageService.reorderStages(reversed, in: pipeline, context: context)
        // Verify each stage's position property was updated correctly
        for (index, stage) in reversed.enumerated() {
            #expect(stage.position == index)
        }
    }

    @Test("deleteStage succeeds when no models present")
    @MainActor
    func deleteStageNoModels() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let last = pipeline.stages.sorted { $0.position < $1.position }.last!

        try StageService.deleteStage(last, context: context)

        let descriptor = FetchDescriptor<Stage>()
        let remaining = try context.fetch(descriptor)
        #expect(!remaining.contains { $0.id == last.id })
    }

    @Test("deleteStage throws stageHasModels when models present")
    @MainActor
    func deleteStageWithModels() throws {
        let (container, pipeline) = try makeContainerAndPipeline()
        let context = container.mainContext
        let firstStage = pipeline.stages.sorted { $0.position < $1.position }.first!

        _ = try ProjectService.createProject(
            name: "Test Project", modelCount: 2, in: pipeline, context: context
        )

        #expect(throws: WMError.stageHasModels(stageName: firstStage.name)) {
            try StageService.deleteStage(firstStage, context: context)
        }
    }
}
