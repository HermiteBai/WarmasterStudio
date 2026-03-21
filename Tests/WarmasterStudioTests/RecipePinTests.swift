import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("RecipePin Tests")
struct RecipePinTests {

    // MARK: - Coordinate clamping in init

    @Test("x and y in [0,1] are stored unchanged")
    func coordinatesInRange() {
        let pin = RecipePin(x: 0.25, y: 0.75, recipeId: UUID(), recipeName: "Test", projectId: UUID())
        #expect(pin.x == 0.25)
        #expect(pin.y == 0.75)
    }

    @Test("x > 1 is clamped to 1")
    func xClampedToMax() {
        let pin = RecipePin(x: 1.5, y: 0.5, recipeId: UUID(), recipeName: "Test", projectId: UUID())
        #expect(pin.x == 1.0)
    }

    @Test("x < 0 is clamped to 0")
    func xClampedToMin() {
        let pin = RecipePin(x: -0.1, y: 0.5, recipeId: UUID(), recipeName: "Test", projectId: UUID())
        #expect(pin.x == 0.0)
    }

    @Test("y > 1 is clamped to 1")
    func yClampedToMax() {
        let pin = RecipePin(x: 0.5, y: 99.0, recipeId: UUID(), recipeName: "Test", projectId: UUID())
        #expect(pin.y == 1.0)
    }

    @Test("y < 0 is clamped to 0")
    func yClampedToMin() {
        let pin = RecipePin(x: 0.5, y: -5.0, recipeId: UUID(), recipeName: "Test", projectId: UUID())
        #expect(pin.y == 0.0)
    }

    @Test("both x and y out of range are both clamped")
    func bothCoordinatesClamped() {
        let pin = RecipePin(x: -10.0, y: 10.0, recipeId: UUID(), recipeName: "Test", projectId: UUID())
        #expect(pin.x == 0.0)
        #expect(pin.y == 1.0)
    }

    @Test("boundary values 0.0 and 1.0 are accepted exactly")
    func boundaryValuesAccepted() {
        let topLeft     = RecipePin(x: 0.0, y: 0.0, recipeId: UUID(), recipeName: "T", projectId: UUID())
        let bottomRight = RecipePin(x: 1.0, y: 1.0, recipeId: UUID(), recipeName: "T", projectId: UUID())
        #expect(topLeft.x == 0.0 && topLeft.y == 0.0)
        #expect(bottomRight.x == 1.0 && bottomRight.y == 1.0)
    }

    // MARK: - Normalisation accuracy

    @Test("centre coordinates are stored with full precision")
    func centrePrecision() {
        let pin = RecipePin(x: 0.5, y: 0.5, recipeId: UUID(), recipeName: "Centre", projectId: UUID())
        #expect(pin.x == 0.5)
        #expect(pin.y == 0.5)
    }

    @Test("sub-pixel precision is preserved")
    func subPixelPrecision() {
        let pin = RecipePin(x: 0.123456789, y: 0.987654321,
                            recipeId: UUID(), recipeName: "T", projectId: UUID())
        // Allow tiny floating-point tolerance.
        #expect(abs(pin.x - 0.123456789) < 1e-9)
        #expect(abs(pin.y - 0.987654321) < 1e-9)
    }

    // MARK: - Identity and metadata

    @Test("each pin gets a unique id by default")
    func uniqueIds() {
        let a = RecipePin(x: 0.1, y: 0.1, recipeId: UUID(), recipeName: "A", projectId: UUID())
        let b = RecipePin(x: 0.1, y: 0.1, recipeId: UUID(), recipeName: "B", projectId: UUID())
        #expect(a.id != b.id)
    }

    @Test("custom id is preserved")
    func customId() {
        let id = UUID()
        let pin = RecipePin(id: id, x: 0.5, y: 0.5, recipeId: UUID(), recipeName: "T", projectId: UUID())
        #expect(pin.id == id)
    }

    @Test("recipeName is stored verbatim")
    func recipeNameStored() {
        let pin = RecipePin(x: 0.0, y: 0.0, recipeId: UUID(),
                            recipeName: "Ork Skin — Warboss Green", projectId: UUID())
        #expect(pin.recipeName == "Ork Skin — Warboss Green")
    }

    @Test("projectId and recipeId are stored independently")
    func idsSeparated() {
        let projectId = UUID()
        let recipeId  = UUID()
        let pin = RecipePin(x: 0.5, y: 0.5, recipeId: recipeId, recipeName: "T", projectId: projectId)
        #expect(pin.projectId == projectId)
        #expect(pin.recipeId  == recipeId)
        #expect(pin.projectId != pin.recipeId)
    }

    // MARK: - SwiftData persistence

    @MainActor
    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: RecipePin.self, configurations: config)
    }

    @Test("pin persists to SwiftData and is fetchable")
    @MainActor
    func pinPersists() throws {
        let ctx    = try makeContainer().mainContext
        let projId = UUID()
        let recId  = UUID()
        let pin    = RecipePin(x: 0.33, y: 0.66, recipeId: recId, recipeName: "Shading", projectId: projId)
        ctx.insert(pin)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<RecipePin>())
        #expect(fetched.count == 1)
        #expect(abs(fetched[0].x - 0.33) < 1e-9)
        #expect(abs(fetched[0].y - 0.66) < 1e-9)
        #expect(fetched[0].recipeId  == recId)
        #expect(fetched[0].projectId == projId)
    }

    @Test("multiple pins for same project are all fetchable")
    @MainActor
    func multiplePinsSameProject() throws {
        let ctx    = try makeContainer().mainContext
        let projId = UUID()
        for i in 0..<5 {
            let pin = RecipePin(x: Double(i) * 0.2, y: 0.5,
                                recipeId: UUID(), recipeName: "Step \(i)", projectId: projId)
            ctx.insert(pin)
        }
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<RecipePin>())
        let projectPins = fetched.filter { $0.projectId == projId }
        #expect(projectPins.count == 5)
    }

    @Test("deleting a pin removes it from the store")
    @MainActor
    func deletePinRemovesIt() throws {
        let ctx = try makeContainer().mainContext
        let pin = RecipePin(x: 0.5, y: 0.5, recipeId: UUID(), recipeName: "T", projectId: UUID())
        ctx.insert(pin)
        try ctx.save()
        ctx.delete(pin)
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<RecipePin>())
        #expect(fetched.isEmpty)
    }

    // MARK: - Normalisation helper (mirrors BoxArtPinCanvas logic)

    /// Mirrors the private `normalise(_:in:)` helper in BoxArtPinCanvas to
    /// verify the coordinate math independently.
    private func normalise(_ pt: (x: CGFloat, y: CGFloat),
                           in size: (w: CGFloat, h: CGFloat)) -> (x: Double, y: Double) {
        let nx = max(0, min(1, size.w > 0 ? Double(pt.x / size.w) : 0))
        let ny = max(0, min(1, size.h > 0 ? Double(pt.y / size.h) : 0))
        return (nx, ny)
    }

    @Test("normalise maps canvas point to [0,1] range")
    func normaliseInRange() {
        let n = normalise((x: 200, y: 150), in: (w: 400, h: 300))
        #expect(n.x == 0.5)
        #expect(n.y == 0.5)
    }

    @Test("normalise clamps point beyond right/bottom edge")
    func normaliseClampsMax() {
        let n = normalise((x: 500, y: 400), in: (w: 400, h: 300))
        #expect(n.x == 1.0)
        #expect(n.y == 1.0)
    }

    @Test("normalise clamps negative point to 0")
    func normaliseClampsMin() {
        let n = normalise((x: -10, y: -5), in: (w: 400, h: 300))
        #expect(n.x == 0.0)
        #expect(n.y == 0.0)
    }

    @Test("normalise returns 0 when canvas dimension is 0")
    func normaliseZeroDimension() {
        let n = normalise((x: 50, y: 50), in: (w: 0, h: 0))
        #expect(n.x == 0.0)
        #expect(n.y == 0.0)
    }
}

// CGFloat is defined in CoreGraphics; import it only for the helper above.
import CoreGraphics
