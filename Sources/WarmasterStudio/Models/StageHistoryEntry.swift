import Foundation
import SwiftData

/// Records the time a single ModelRecord spent in a pipeline stage.
/// Created when a model enters a stage; `leftAt` is set when it leaves.
@Model
final class StageHistoryEntry {
    var id: UUID
    /// The ModelRecord this entry belongs to.
    var modelRecordId: UUID
    /// The project this record belongs to (denormalised for query efficiency).
    var projectId: UUID
    /// The collection this project belongs to (nullable, for filtering).
    var collectionId: UUID?
    /// The stage this entry records time in.
    var stageId: UUID
    /// Denormalised stage name — survives stage renaming gracefully.
    var stageName: String
    /// When the model entered this stage.
    var enteredAt: Date
    /// When the model left this stage. nil = model is still here.
    var leftAt: Date?

    /// Time spent in stage. nil if the model is still in this stage.
    var duration: TimeInterval? {
        guard let left = leftAt else { return nil }
        return left.timeIntervalSince(enteredAt)
    }

    init(
        id: UUID = UUID(),
        modelRecordId: UUID,
        projectId: UUID,
        collectionId: UUID?,
        stageId: UUID,
        stageName: String,
        enteredAt: Date = .now
    ) {
        self.id = id
        self.modelRecordId = modelRecordId
        self.projectId = projectId
        self.collectionId = collectionId
        self.stageId = stageId
        self.stageName = stageName
        self.enteredAt = enteredAt
        self.leftAt = nil
    }
}
