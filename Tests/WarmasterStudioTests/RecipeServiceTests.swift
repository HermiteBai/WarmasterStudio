import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("RecipeService Tests")
struct RecipeServiceTests {

    @MainActor
    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: PaintRecipe.self, RecipeStep.self,
            configurations: config
        )
    }

    // MARK: - Recipe CRUD

    @Test("createRecipe inserts a recipe with correct name")
    @MainActor
    func createRecipe() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Ultramarines Blue", projectId: nil, context: ctx)
        #expect(recipe.name == "Ultramarines Blue")
        let fetched = try ctx.fetch(FetchDescriptor<PaintRecipe>())
        #expect(fetched.count == 1)
    }

    @Test("updateRecipe changes the name")
    @MainActor
    func updateRecipeName() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Draft Name", projectId: nil, context: ctx)
        try RecipeService.updateRecipe(recipe, name: "Ork Green Skin", context: ctx)
        #expect(recipe.name == "Ork Green Skin")
    }

    @Test("deleteRecipe removes it from the store")
    @MainActor
    func deleteRecipe() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Throwaway", projectId: nil, context: ctx)
        try RecipeService.deleteRecipe(recipe, context: ctx)
        let fetched = try ctx.fetch(FetchDescriptor<PaintRecipe>())
        #expect(fetched.isEmpty)
    }

    // MARK: - Step ordering

    @Test("addStep appends steps with monotonically increasing positions")
    @MainActor
    func addStepPositions() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Test Recipe", projectId: nil, context: ctx)
        let s0 = try RecipeService.addStep(to: recipe, paintId: nil, paintName: "Base Brown",
                                           technique: .basecoat, notes: "", context: ctx)
        let s1 = try RecipeService.addStep(to: recipe, paintId: nil, paintName: "Shadow Black",
                                           technique: .shade, notes: "", context: ctx)
        let s2 = try RecipeService.addStep(to: recipe, paintId: nil, paintName: "Highlight Bone",
                                           technique: .highlight, notes: "", context: ctx)

        #expect(s0.position == 0)
        #expect(s1.position == 1)
        #expect(s2.position == 2)
        #expect(recipe.steps.count == 3)
    }

    @Test("reorderSteps swaps two steps correctly")
    @MainActor
    func reorderSteps() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Reorder Test", projectId: nil, context: ctx)
        try RecipeService.addStep(to: recipe, paintId: nil, paintName: "A", technique: .basecoat, notes: "", context: ctx)
        try RecipeService.addStep(to: recipe, paintId: nil, paintName: "B", technique: .layer, notes: "", context: ctx)
        try RecipeService.addStep(to: recipe, paintId: nil, paintName: "C", technique: .highlight, notes: "", context: ctx)

        // Move item at index 0 → position after index 2 (i.e. to end).
        try RecipeService.reorderSteps(in: recipe, fromOffsets: IndexSet([0]), toOffset: 3, context: ctx)

        let sorted = recipe.steps.sorted { $0.position < $1.position }
        #expect(sorted[0].paintName == "B")
        #expect(sorted[1].paintName == "C")
        #expect(sorted[2].paintName == "A")
    }

    @Test("positions are contiguous 0-based after reorder")
    @MainActor
    func positionsContiguousAfterReorder() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Contiguous", projectId: nil, context: ctx)
        for i in 0..<5 {
            try RecipeService.addStep(to: recipe, paintId: nil, paintName: "Step \(i)",
                                      technique: .layer, notes: "", context: ctx)
        }
        try RecipeService.reorderSteps(in: recipe, fromOffsets: IndexSet([4]), toOffset: 1, context: ctx)
        let positions = recipe.steps.sorted { $0.position < $1.position }.map(\.position)
        #expect(positions == [0, 1, 2, 3, 4])
    }

    @Test("deleteStep removes step and does not leave gaps")
    @MainActor
    func deleteStepRemoves() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Delete Step Test", projectId: nil, context: ctx)
        let s0 = try RecipeService.addStep(to: recipe, paintId: nil, paintName: "A", technique: .basecoat, notes: "", context: ctx)
        try RecipeService.addStep(to: recipe, paintId: nil, paintName: "B", technique: .layer, notes: "", context: ctx)
        try RecipeService.deleteStep(s0, context: ctx)
        #expect(recipe.steps.count == 1)
        // After deletion the remaining step should no longer reference the deleted one
        let fetched = try ctx.fetch(FetchDescriptor<RecipeStep>())
        #expect(fetched.count == 1)
        #expect(fetched[0].paintName == "B")
    }

    // MARK: - Technique enum

    @Test("Technique has all expected cases")
    func techniqueAllCases() {
        let expected: Set<Technique> = [
            .basecoat, .layer, .shade, .drybrush,
            .highlight, .glaze, .stipple, .edge, .other
        ]
        #expect(Set(Technique.allCases) == expected)
    }

    @Test("Every Technique case has a non-empty systemImage")
    func techniqueSystemImages() {
        for technique in Technique.allCases {
            #expect(!technique.systemImage.isEmpty,
                    "Technique.\(technique.rawValue) has empty systemImage")
        }
    }

    @Test("Technique rawValues are stable for Codable persistence")
    func techniqueRawValueStability() {
        let cases: [(Technique, String)] = [
            (.basecoat, "Basecoat"), (.layer, "Layer"), (.shade, "Shade"),
            (.drybrush, "Drybrush"), (.highlight, "Highlight"), (.glaze, "Glaze"),
            (.stipple, "Stipple"), (.edge, "Edge"), (.other, "Other")
        ]
        for (technique, raw) in cases {
            #expect(technique.rawValue == raw)
        }
    }

    @Test("Technique is Codable round-trip")
    func techniqueCodable() throws {
        for technique in Technique.allCases {
            let data = try JSONEncoder().encode(technique)
            let decoded = try JSONDecoder().decode(Technique.self, from: data)
            #expect(decoded == technique)
        }
    }

    // MARK: - Step with notes

    @Test("addStep stores notes correctly")
    @MainActor
    func addStepNotes() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "Notes Test", projectId: nil, context: ctx)
        let step = try RecipeService.addStep(to: recipe, paintId: nil, paintName: "Red",
                                             technique: .layer, notes: "Thin 1:2 with medium",
                                             context: ctx)
        #expect(step.notes == "Thin 1:2 with medium")
    }

    @Test("addStep with paintId stores the paintId reference")
    @MainActor
    func addStepPaintIdReference() throws {
        let ctx = try makeContainer().mainContext
        let recipe = try RecipeService.createRecipe(name: "PaintId Test", projectId: nil, context: ctx)
        let paintId = UUID()
        let step = try RecipeService.addStep(to: recipe, paintId: paintId, paintName: "Macragge Blue",
                                             technique: .basecoat, notes: "", context: ctx)
        #expect(step.paintId == paintId)
        #expect(step.paintName == "Macragge Blue")
    }

    // MARK: - Multi-recipe isolation

    @Test("steps from different recipes are independent")
    @MainActor
    func stepsAreRecipeScoped() throws {
        let ctx = try makeContainer().mainContext
        let r1 = try RecipeService.createRecipe(name: "Recipe A", projectId: nil, context: ctx)
        let r2 = try RecipeService.createRecipe(name: "Recipe B", projectId: nil, context: ctx)
        try RecipeService.addStep(to: r1, paintId: nil, paintName: "R1S1", technique: .basecoat, notes: "", context: ctx)
        try RecipeService.addStep(to: r1, paintId: nil, paintName: "R1S2", technique: .layer, notes: "", context: ctx)
        try RecipeService.addStep(to: r2, paintId: nil, paintName: "R2S1", technique: .shade, notes: "", context: ctx)

        #expect(r1.steps.count == 2)
        #expect(r2.steps.count == 1)
    }
}
