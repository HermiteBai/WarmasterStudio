import Foundation

public struct ProjectService {

    /// Creates a Project and N ModelRecords all placed in the first stage.
    @discardableResult
    public static func createProject(
        name: String,
        modelCount: Int,
        collectionId: UUID? = nil,
        notes: String? = nil,
        in pipeline: Pipeline,
        context: DataContext
    ) throws -> Project {
        guard modelCount > 0 else { throw WMError.invalidModelCount }

        let sortedStages = pipeline.stages.sorted { $0.position < $1.position }
        guard let firstStage = sortedStages.first else { throw WMError.stageNotFound }

        let project = Project(
            name: name,
            modelCount: modelCount,
            collectionId: collectionId,
            notes: notes
        )
        context.insert(project)

        for _ in 0..<modelCount {
            let record = ModelRecord(projectId: project.id, currentStageId: firstStage.id)
            context.insert(record)
            project.modelRecords.append(record)
        }

        try context.save()
        return project
    }

    /// Updates mutable fields on a project.
    public static func updateProject(
        _ project: Project,
        name: String,
        collectionId: UUID? = nil,
        notes: String? = nil,
        context: DataContext
    ) throws {
        project.name = name
        project.collectionId = collectionId
        project.notes = notes
        try context.save()
    }

    /// Deletes a project and all its ModelRecords (cascade).
    public static func deleteProject(_ project: Project, context: DataContext) throws {
        context.delete(project)
        try context.save()
    }
}
