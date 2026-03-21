import Foundation
import SwiftData

@Model
final class PaintRecipe {
    var id: UUID
    var name: String
    var projectId: UUID?  // optional — recipes can be global or project-scoped
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var steps: [RecipeStep]

    init(
        id: UUID = UUID(),
        name: String,
        projectId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectId = projectId
        self.createdAt = createdAt
        self.steps = []
    }
}
