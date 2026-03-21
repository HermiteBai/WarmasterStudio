import Foundation

public struct StageService {

    /// Appends a new stage to the pipeline.
    @discardableResult
    public static func addStage(name: String, to pipeline: Pipeline, context: DataContext) throws -> Stage {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }

        let nextPosition = (pipeline.stages.map(\.position).max() ?? -1) + 1
        let stage = Stage(name: trimmed, position: nextPosition)
        context.insert(stage)
        pipeline.stages.append(stage)
        try context.save()
        return stage
    }

    /// Renames an existing stage. Validates non-empty.
    public static func renameStage(_ stage: Stage, to newName: String, context: DataContext) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }
        stage.name = trimmed
        try context.save()
    }

    /// Updates position values for all stages in the pipeline based on provided ordered array.
    public static func reorderStages(_ stages: [Stage], in pipeline: Pipeline, context: DataContext) throws {
        for (index, stage) in stages.enumerated() {
            stage.position = index
        }
        pipeline.stages = stages
        try context.save()
    }

    /// Deletes a stage. Throws WMError.stageHasModels if any ModelRecord references it.
    public static func deleteStage(_ stage: Stage, context: DataContext) throws {
        let stageId = stage.id
        let records = context.fetchModelRecords(where: { $0.currentStageId == stageId })
        guard records.isEmpty else { throw WMError.stageHasModels(stageName: stage.name) }
        context.delete(stage)
        try context.save()
    }
}
