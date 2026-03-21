import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("ModelProgressService Tests")
struct ModelProgressServiceTests {

    @MainActor
    func makeContainerPipelineProject() throws -> (ModelContainer, Pipeline, Project) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
            configurations: config
        )
        let context = container.mainContext
        let pipeline = try PipelineService.bootstrap(context: context)
        let project = try ProjectService.createProject(
            name: "Test Project", modelCount: 5, in: pipeline, context: context
        )
        return (container, pipeline, project)
    }

    @Test("moveModels updates correct ModelRecords")
    @MainActor
    func moveModels() throws {
        let (container, pipeline, project) = try makeContainerPipelineProject()
        let context = container.mainContext
        let stages = pipeline.stages.sorted { $0.position < $1.position }
        let fromStage = stages[0]
        let toStage = stages[1]

        try ModelProgressService.moveModels(
            count: 3, fromStageId: fromStage.id, toStageId: toStage.id,
            inProject: project, context: context
        )

        let atFrom = project.modelRecords.filter { $0.currentStageId == fromStage.id }
        let atTo = project.modelRecords.filter { $0.currentStageId == toStage.id }
        #expect(atFrom.count == 2)
        #expect(atTo.count == 3)
    }

    @Test("moveModels fails when count exceeds available")
    @MainActor
    func moveModelsInsufficientCount() throws {
        let (container, pipeline, project) = try makeContainerPipelineProject()
        let context = container.mainContext
        let stages = pipeline.stages.sorted { $0.position < $1.position }
        let fromStage = stages[0]
        let toStage = stages[1]

        #expect(throws: WMError.insufficientModelsAtStage) {
            try ModelProgressService.moveModels(
                count: 10, fromStageId: fromStage.id, toStageId: toStage.id,
                inProject: project, context: context
            )
        }
    }
}
