import Foundation
import SwiftData
import os

struct StageService {

    /// Appends a new stage to the pipeline.
    static func addStage(name: String, to pipeline: Pipeline, context: ModelContext) throws -> Stage {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }

        let nextPosition = (pipeline.stages.map(\.position).max() ?? -1) + 1
        let stage = Stage(name: trimmed, position: nextPosition)
        context.insert(stage)
        pipeline.stages.append(stage)
        try context.save()
        Logger.stage.info("Added stage '\(trimmed)' at position \(nextPosition).")
        return stage
    }

    /// Renames an existing stage. Validates non-empty.
    static func renameStage(_ stage: Stage, to newName: String, context: ModelContext) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WMError.emptyName }
        Logger.stage.info("Renaming stage '\(stage.name)' to '\(trimmed)'.")
        stage.name = trimmed
        try context.save()
    }

    /// Updates position values for all stages in the pipeline based on provided ordered array.
    static func reorderStages(_ stages: [Stage], in pipeline: Pipeline, context: ModelContext) throws {
        for (index, stage) in stages.enumerated() {
            stage.position = index
        }
        pipeline.stages = stages
        try context.save()
        Logger.stage.info("Reordered \(stages.count) stages.")
    }

    /// Deletes a stage. Throws WMError.stageHasModels if any ModelRecord references it.
    static func deleteStage(_ stage: Stage, context: ModelContext) throws {
        Logger.stage.debug("Attempting to delete stage '\(stage.name)'.")
        let stageId = stage.id
        let descriptor = FetchDescriptor<ModelRecord>(
            predicate: #Predicate { $0.currentStageId == stageId }
        )
        let records = try context.fetch(descriptor)
        guard records.isEmpty else {
            Logger.stage.error("Cannot delete stage '\(stage.name)': \(records.count) model(s) present.")
            throw WMError.stageHasModels(stageName: stage.name)
        }
        context.delete(stage)
        try context.save()
        Logger.stage.info("Deleted stage '\(stage.name)'.")
    }
}
