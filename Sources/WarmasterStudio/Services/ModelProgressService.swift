import Foundation
import SwiftData
import os

struct ModelProgressService {

    /// Moves `count` ModelRecords from fromStageId to toStageId within a project.
    static func moveModels(
        count: Int,
        fromStageId: UUID,
        toStageId: UUID,
        inProject project: Project,
        context: ModelContext
    ) throws {
        guard count > 0 else { throw WMError.invalidModelCount }

        let atSource = project.modelRecords.filter { $0.currentStageId == fromStageId }
        guard atSource.count >= count else {
            Logger.modelProgress.error(
                "Insufficient models at source stage: requested \(count), available \(atSource.count)."
            )
            throw WMError.insufficientModelsAtStage
        }

        let toMove = Array(atSource.prefix(count))
        for record in toMove {
            record.currentStageId = toStageId
        }

        try context.save()
        Logger.modelProgress.info(
            "Moved \(count) model(s) from stage \(fromStageId) to \(toStageId) in project '\(project.name)'."
        )
    }
}
