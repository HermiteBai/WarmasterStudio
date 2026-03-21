import Foundation
import SwiftData

enum Technique: String, Codable, CaseIterable {
    case basecoat  = "Basecoat"
    case layer     = "Layer"
    case shade     = "Shade"
    case drybrush  = "Drybrush"
    case highlight = "Highlight"
    case glaze     = "Glaze"
    case stipple   = "Stipple"
    case edge      = "Edge"
    case other     = "Other"

    var systemImage: String {
        switch self {
        case .basecoat:  return "paintbrush.fill"
        case .layer:     return "square.stack.fill"
        case .shade:     return "shadow"
        case .drybrush:  return "paintbrush"
        case .highlight: return "sun.max.fill"
        case .glaze:     return "drop.fill"
        case .stipple:   return "circle.dotted"
        case .edge:      return "trapezoid.and.line.horizontal.fill"
        case .other:     return "ellipsis.circle.fill"
        }
    }
}

@Model
final class RecipeStep {
    var id: UUID
    var position: Int
    var paintId: UUID?     // reference to Paint.id
    var paintName: String  // denormalised for display even if paint deleted
    var technique: Technique
    var notes: String
    var recipe: PaintRecipe?

    init(
        id: UUID = UUID(),
        position: Int,
        paintId: UUID? = nil,
        paintName: String,
        technique: Technique,
        notes: String = "",
        recipe: PaintRecipe? = nil
    ) {
        self.id = id
        self.position = position
        self.paintId = paintId
        self.paintName = paintName
        self.technique = technique
        self.notes = notes
        self.recipe = recipe
    }
}
