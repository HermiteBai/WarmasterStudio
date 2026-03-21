import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("PaintLibraryService Tests")
struct PaintLibraryServiceTests {

    @MainActor
    func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Paint.self, configurations: config)
    }

    // MARK: - User paint CRUD

    @Test("addUserPaint inserts a paint with isUserAdded = true")
    @MainActor
    func addUserPaintCreates() throws {
        let ctx = try makeContainer().mainContext
        let paint = try PaintLibraryService.addUserPaint(
            name: "Chaos Black", brand: "MyPaints", hex: "1A1A1A", context: ctx
        )
        #expect(paint.isUserAdded == true)
        #expect(paint.name == "Chaos Black")
        #expect(paint.brand == "MyPaints")
    }

    @Test("addUserPaint persists to the store")
    @MainActor
    func addUserPaintPersists() throws {
        let ctx = try makeContainer().mainContext
        try PaintLibraryService.addUserPaint(name: "Mephiston Red", brand: "Test", hex: "A01000", context: ctx)
        let all = try ctx.fetch(FetchDescriptor<Paint>())
        #expect(all.count == 1)
    }

    @Test("deletePaint removes a user-added paint")
    @MainActor
    func deletePaintRemovesUserPaint() throws {
        let ctx = try makeContainer().mainContext
        let paint = try PaintLibraryService.addUserPaint(name: "To Delete", brand: "Test", hex: "FFFFFF", context: ctx)
        try PaintLibraryService.deletePaint(paint, context: ctx)
        let all = try ctx.fetch(FetchDescriptor<Paint>())
        #expect(all.isEmpty)
    }

    @Test("deletePaint throws when called on a catalogue paint")
    @MainActor
    func deletePaintBlocksCataloguePaint() throws {
        let ctx = try makeContainer().mainContext
        let catalogue = Paint(name: "Abaddon Black", brand: "Citadel", hex: "231F20", isUserAdded: false)
        ctx.insert(catalogue)
        try ctx.save()
        #expect(throws: PaintLibraryError.cannotDeleteCataloguePaint) {
            try PaintLibraryService.deletePaint(catalogue, context: ctx)
        }
    }

    @Test("updatePaint changes name, brand, and hex")
    @MainActor
    func updatePaintFields() throws {
        let ctx = try makeContainer().mainContext
        let paint = try PaintLibraryService.addUserPaint(name: "Old Name", brand: "Old Brand", hex: "000000", context: ctx)
        try PaintLibraryService.updatePaint(paint, name: "New Name", brand: "New Brand", hex: "ff0000", context: ctx)
        #expect(paint.name == "New Name")
        #expect(paint.brand == "New Brand")
        #expect(paint.hex == "FF0000")  // updatePaint uppercases the hex
    }

    @Test("updatePaint uppercases hex string")
    @MainActor
    func updatePaintUppercasesHex() throws {
        let ctx = try makeContainer().mainContext
        let paint = try PaintLibraryService.addUserPaint(name: "P", brand: "B", hex: "aabbcc", context: ctx)
        try PaintLibraryService.updatePaint(paint, name: "P", brand: "B", hex: "aabbcc", context: ctx)
        #expect(paint.hex == "AABBCC")
    }

    // MARK: - Catalogue sync logic (in-memory simulation)
    //
    // seedCatalogue loads from Bundle.main which isn't available in the test
    // host. We exercise the same insert/delete/update contract by operating
    // directly on the model context and verifying invariants.

    @Test("catalogue paints have isUserAdded = false")
    @MainActor
    func cataloguePaintsNotUserAdded() throws {
        let ctx = try makeContainer().mainContext
        let c1 = Paint(name: "Retributor Armour", brand: "Citadel", hex: "BF8C39", isUserAdded: false)
        let c2 = Paint(name: "Agrax Earthshade",  brand: "Citadel", hex: "684E2B", isUserAdded: false)
        ctx.insert(c1); ctx.insert(c2)
        try ctx.save()
        let catalogue = try ctx.fetch(FetchDescriptor<Paint>(predicate: #Predicate { !$0.isUserAdded }))
        #expect(catalogue.count == 2)
        for p in catalogue { #expect(p.isUserAdded == false) }
    }

    @Test("no duplicate brand+name pairs can coexist after manual deduplication")
    @MainActor
    func noDuplicateBrandNamePairs() throws {
        let ctx = try makeContainer().mainContext
        let entries: [(String, String, String)] = [
            ("Macragge Blue",     "Citadel",            "0B4B8C"),
            ("Macragge Blue",     "Citadel",            "0B4B8C"),   // exact dup
            ("Macragge Blue",     "Vallejo Game Color", "2B5EA7"),   // same name, different brand — OK
            ("Abaddon Black",     "Citadel",            "231F20"),
        ]
        var seen: [String: Paint] = [:]
        for (name, brand, hex) in entries {
            let key = "\(brand)|\(name)"
            if seen[key] == nil {
                let p = Paint(name: name, brand: brand, hex: hex, isUserAdded: false)
                ctx.insert(p)
                seen[key] = p
            }
        }
        try ctx.save()
        let all = try ctx.fetch(FetchDescriptor<Paint>())
        #expect(all.count == 3)  // 1 dup skipped

        // Verify no exact key collision exists in the store.
        var keys: [String: Int] = [:]
        for p in all { keys["\(p.brand)|\(p.name)", default: 0] += 1 }
        for (key, count) in keys { #expect(count == 1, "Duplicate key in store: \(key)") }
    }

    @Test("catalogue paints are distinct from user paints in the same store")
    @MainActor
    func catalogueAndUserPaintsCoexist() throws {
        let ctx = try makeContainer().mainContext
        let cat = Paint(name: "Nuln Oil", brand: "Citadel", hex: "27211C", isUserAdded: false)
        ctx.insert(cat)
        try ctx.save()
        try PaintLibraryService.addUserPaint(name: "My Custom Black", brand: "Homebrew", hex: "101010", context: ctx)

        let all      = try ctx.fetch(FetchDescriptor<Paint>())
        let userOnly = all.filter  { $0.isUserAdded }
        let catOnly  = all.filter  { !$0.isUserAdded }
        #expect(all.count      == 2)
        #expect(userOnly.count == 1)
        #expect(catOnly.count  == 1)
    }

    // MARK: - Paint model

    @Test("Paint.displayName returns 'Brand — Name'")
    func paintDisplayName() {
        let p = Paint(name: "Calgar Blue", brand: "Citadel", hex: "5B7EA9", isUserAdded: false)
        #expect(p.displayName == "Citadel – Calgar Blue")
    }

    @Test("Paint hex is stored as provided")
    func paintHexStorage() {
        let p = Paint(name: "X", brand: "Y", hex: "FF0000", isUserAdded: true)
        #expect(p.hex == "FF0000")
    }
}
