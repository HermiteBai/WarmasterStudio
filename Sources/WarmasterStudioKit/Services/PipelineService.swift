import Foundation

public struct PipelineService {
    public static let defaultStageNames = ["On Sprue", "Assembled", "Primed", "Painting", "Done"]

    /// Fetches or creates the singleton Pipeline. Seeds default stages on first run.
    @discardableResult
    public static func bootstrap(context: DataContext) throws -> Pipeline {
        let existing = context.fetchPipelines()
        if let pipeline = existing.first { return pipeline }

        let pipeline = Pipeline()
        context.insert(pipeline)

        for (index, stageName) in defaultStageNames.enumerated() {
            let stage = Stage(name: stageName, position: index)
            context.insert(stage)
            pipeline.stages.append(stage)
        }

        try context.save()
        return pipeline
    }
}
