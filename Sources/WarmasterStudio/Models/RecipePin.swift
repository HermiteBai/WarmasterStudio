import Foundation
import SwiftData

/// A pin placed on a box-art image that references a paint recipe.
/// Coordinates are normalised (0–1) relative to the image's rendered size.
@Model
final class RecipePin {
    var id: UUID
    /// Normalised x position (0 = left edge, 1 = right edge).
    var x: Double
    /// Normalised y position (0 = top edge, 1 = bottom edge).
    var y: Double
    /// The recipe this pin links to.
    var recipeId: UUID
    /// Denormalised recipe name — survives recipe deletion gracefully.
    var recipeName: String
    /// The project this pin belongs to.
    var projectId: UUID

    init(
        id: UUID = UUID(),
        x: Double,
        y: Double,
        recipeId: UUID,
        recipeName: String,
        projectId: UUID
    ) {
        self.id = id
        self.x = max(0, min(1, x))
        self.y = max(0, min(1, y))
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.projectId = projectId
    }
}
