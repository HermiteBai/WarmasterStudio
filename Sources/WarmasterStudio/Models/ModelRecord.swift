import Foundation
import SwiftData

@Model
final class ModelRecord {
    var id: UUID
    var projectId: UUID
    var currentStageId: UUID

    @Relationship(inverse: \Project.modelRecords)
    var project: Project?

    init(id: UUID = UUID(), projectId: UUID, currentStageId: UUID) {
        self.id = id
        self.projectId = projectId
        self.currentStageId = currentStageId
    }
}
