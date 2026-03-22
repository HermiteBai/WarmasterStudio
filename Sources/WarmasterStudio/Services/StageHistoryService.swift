import Foundation
import SwiftData

struct StageHistoryService {

    /// Call after ModelProgressService.moveModels to record the stage transition.
    static func recordMove(
        records: [ModelRecord],
        fromStageId: UUID,
        fromStageName: String,
        toStageId: UUID,
        toStageName: String,
        projectId: UUID,
        collectionId: UUID?,
        context: ModelContext
    ) throws {
        let now = Date.now
        for record in records {
            // Close the open entry for the from-stage
            let recordId = record.id
            let descriptor = FetchDescriptor<StageHistoryEntry>(
                predicate: #Predicate {
                    $0.modelRecordId == recordId &&
                    $0.stageId == fromStageId &&
                    $0.leftAt == nil
                }
            )
            if let open = try context.fetch(descriptor).first {
                open.leftAt = now
            }
            // Open a new entry for the to-stage
            context.insert(StageHistoryEntry(
                modelRecordId: record.id,
                projectId: projectId,
                collectionId: collectionId,
                stageId: toStageId,
                stageName: toStageName,
                enteredAt: now
            ))
        }
        try context.save()
    }

    /// Call when models are first created to seed their initial stage entry.
    static func recordCreation(
        records: [ModelRecord],
        initialStageId: UUID,
        initialStageName: String,
        projectId: UUID,
        collectionId: UUID?,
        context: ModelContext
    ) throws {
        for record in records {
            context.insert(StageHistoryEntry(
                modelRecordId: record.id,
                projectId: projectId,
                collectionId: collectionId,
                stageId: initialStageId,
                stageName: initialStageName,
                enteredAt: .now
            ))
        }
        try context.save()
    }
}
