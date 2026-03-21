import Foundation
import SwiftData
import os

struct PipelineService {
    static let defaultStageNames = ["On Sprue", "Assembled", "Primed", "Painting", "Done"]

    /// Fetches or creates the singleton Pipeline. Seeds default stages on first run.
    @discardableResult
    static func bootstrap(context: ModelContext) throws -> Pipeline {
        let descriptor = FetchDescriptor<Pipeline>()
        let existing = try context.fetch(descriptor)

        if let pipeline = existing.first {
            Logger.pipeline.debug("Found existing pipeline with \(pipeline.stages.count) stages.")
            return pipeline
        }

        Logger.pipeline.info("No pipeline found — creating default pipeline with \(defaultStageNames.count) stages.")
        let pipeline = Pipeline()
        context.insert(pipeline)

        for (index, stageName) in defaultStageNames.enumerated() {
            let stage = Stage(name: stageName, position: index)
            context.insert(stage)
            pipeline.stages.append(stage)
        }

        try context.save()
        Logger.pipeline.info("Pipeline created with default stages.")
        return pipeline
    }
}
