import Foundation

struct KanbanCard: Identifiable, Equatable {
    let id: UUID          // project.id
    let projectId: UUID
    let stageId: UUID
    let projectName: String
    let collectionName: String?
    let collectionId: UUID?
    let modelCount: Int
    let linkGroupId: UUID?
}
