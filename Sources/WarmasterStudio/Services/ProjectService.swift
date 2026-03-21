import Foundation
import SwiftData
import os

struct ProjectService {

    /// Creates a Project and N ModelRecords all placed in the first stage.
    @discardableResult
    static func createProject(
        name: String,
        modelCount: Int,
        collectionId: UUID? = nil,
        notes: String? = nil,
        in pipeline: Pipeline,
        context: ModelContext
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
        Logger.project.info("Created project '\(name)' with \(modelCount) model(s) in stage '\(firstStage.name)'.")
        return project
    }

    /// Updates mutable fields on a project.
    static func updateProject(
        _ project: Project,
        name: String,
        collectionId: UUID? = nil,
        notes: String? = nil,
        context: ModelContext
    ) throws {
        project.name = name
        project.collectionId = collectionId
        project.notes = notes
        try context.save()
        Logger.project.info("Updated project '\(name)'.")
    }

    /// Deletes a project and all its ModelRecords (cascade).
    static func deleteProject(_ project: Project, context: ModelContext) throws {
        Logger.project.info("Deleting project '\(project.name)' with \(project.modelRecords.count) model record(s).")
        context.delete(project)
        try context.save()
    }
}
