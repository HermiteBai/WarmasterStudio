import Foundation

public struct ModelProgressService {

    /// Moves `count` ModelRecords from fromStageId to toStageId within a project.
    public static func moveModels(
        count: Int,
        fromStageId: UUID,
        toStageId: UUID,
        inProject project: Project,
        context: DataContext
    ) throws {
        guard count > 0 else { throw WMError.invalidModelCount }

        let atSource = project.modelRecords.filter { $0.currentStageId == fromStageId }
        guard atSource.count >= count else { throw WMError.insufficientModelsAtStage }

        let toMove = Array(atSource.prefix(count))
        for record in toMove { record.currentStageId = toStageId }

        try context.save()
    }
}
