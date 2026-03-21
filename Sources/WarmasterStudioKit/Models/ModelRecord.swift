import Foundation

public final class ModelRecord: Identifiable {
    public let id: UUID
    public var projectId: UUID
    public var currentStageId: UUID
    public weak var project: Project?

    public init(id: UUID = UUID(), projectId: UUID, currentStageId: UUID) {
        self.id = id
        self.projectId = projectId
        self.currentStageId = currentStageId
    }
}
