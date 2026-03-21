import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("PipelineService Tests")
struct PipelineServiceTests {

    @MainActor
    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
            configurations: config
        )
    }

    @Test("Bootstrap creates default stages on first run")
    @MainActor
    func bootstrapCreatesDefaultStages() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let pipeline = try PipelineService.bootstrap(context: context)
        #expect(pipeline.stages.count == PipelineService.defaultStageNames.count)

        let sorted = pipeline.stages.sorted { $0.position < $1.position }
        for (index, name) in PipelineService.defaultStageNames.enumerated() {
            #expect(sorted[index].name == name)
        }
    }

    @Test("Bootstrap does not duplicate stages on second call")
    @MainActor
    func bootstrapDoesNotDuplicate() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try PipelineService.bootstrap(context: context)
        try PipelineService.bootstrap(context: context)

        let descriptor = FetchDescriptor<Pipeline>()
        let pipelines = try context.fetch(descriptor)
        #expect(pipelines.count == 1)
        #expect(pipelines[0].stages.count == PipelineService.defaultStageNames.count)
    }
}
