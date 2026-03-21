import Foundation
import SwiftData
import os

struct RecipeService {

    /// Creates a new PaintRecipe and inserts it into the context.
    @discardableResult
    static func createRecipe(
        name: String,
        projectId: UUID?,
        context: ModelContext
    ) throws -> PaintRecipe {
        let recipe = PaintRecipe(name: name, projectId: projectId)
        context.insert(recipe)
        try context.save()
        Logger.recipe.info("Created recipe: \(recipe.name)")
        return recipe
    }

    /// Appends a new step to a recipe, assigning the next available position.
    @discardableResult
    static func addStep(
        to recipe: PaintRecipe,
        paintId: UUID?,
        paintName: String,
        technique: Technique,
        notes: String,
        context: ModelContext
    ) throws -> RecipeStep {
        let position = (recipe.steps.map(\.position).max() ?? -1) + 1
        let step = RecipeStep(
            position: position,
            paintId: paintId,
            paintName: paintName,
            technique: technique,
            notes: notes,
            recipe: recipe
        )
        context.insert(step)
        recipe.steps.append(step)
        try context.save()
        Logger.recipe.info("Added step \(position) to recipe '\(recipe.name)'")
        return step
    }

    /// Reorders steps within a recipe by moving items and rewriting positions.
    static func reorderSteps(
        in recipe: PaintRecipe,
        fromOffsets: IndexSet,
        toOffset: Int,
        context: ModelContext
    ) throws {
        var sorted = recipe.steps.sorted { $0.position < $1.position }
        sorted.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (index, step) in sorted.enumerated() {
            step.position = index
        }
        try context.save()
        Logger.recipe.debug("Reordered steps in recipe '\(recipe.name)'")
    }

    /// Removes a single step and renumbers remaining steps.
    static func deleteStep(_ step: RecipeStep, context: ModelContext) throws {
        if let recipe = step.recipe {
            recipe.steps.removeAll { $0.id == step.id }
        }
        context.delete(step)
        try context.save()
        Logger.recipe.info("Deleted step '\(step.paintName)'")
    }

    /// Deletes a recipe and all its steps (cascade rule handles steps).
    static func deleteRecipe(_ recipe: PaintRecipe, context: ModelContext) throws {
        context.delete(recipe)
        try context.save()
        Logger.recipe.info("Deleted recipe '\(recipe.name)'")
    }

    /// Updates the name of a recipe.
    static func updateRecipe(_ recipe: PaintRecipe, name: String, context: ModelContext) throws {
        recipe.name = name
        try context.save()
        Logger.recipe.info("Updated recipe name to '\(recipe.name)'")
    }
}
