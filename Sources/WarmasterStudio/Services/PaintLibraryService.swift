import Foundation
import SwiftData
import os

struct PaintLibraryService {

    private struct CataloguePaint: Decodable {
        let name: String
        let brand: String
        let hex: String
    }

    /// Imports catalogue paints from JSON if no catalogue paints exist yet.
    static func seedCatalogue(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Paint>(
            predicate: #Predicate { !$0.isUserAdded }
        )
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            Logger.paint.debug("Paint catalogue already seeded (\(existing.count) entries).")
            return
        }

        guard let url = Bundle.main.url(forResource: "paint_catalogue", withExtension: "json") else {
            Logger.paint.error("paint_catalogue.json not found in bundle.")
            return
        }

        let data = try Data(contentsOf: url)
        let catalogue = try JSONDecoder().decode([CataloguePaint].self, from: data)

        for entry in catalogue {
            let paint = Paint(name: entry.name, brand: entry.brand, hex: entry.hex, isUserAdded: false)
            context.insert(paint)
        }

        try context.save()
        Logger.paint.info("Seeded \(catalogue.count) catalogue paints.")
    }

    /// Adds a new user-defined paint.
    @discardableResult
    static func addUserPaint(name: String, brand: String, hex: String, context: ModelContext) throws -> Paint {
        let paint = Paint(name: name, brand: brand, hex: hex, isUserAdded: true)
        context.insert(paint)
        try context.save()
        Logger.paint.info("Added user paint: \(paint.displayName)")
        return paint
    }

    /// Deletes a paint. Only user-added paints can be deleted.
    static func deletePaint(_ paint: Paint, context: ModelContext) throws {
        guard paint.isUserAdded else {
            Logger.paint.warning("Attempted to delete catalogue paint '\(paint.displayName)' — blocked.")
            throw PaintLibraryError.cannotDeleteCataloguePaint
        }
        context.delete(paint)
        try context.save()
        Logger.paint.info("Deleted user paint: \(paint.displayName)")
    }

    /// Updates name, brand and hex on an existing paint.
    static func updatePaint(_ paint: Paint, name: String, brand: String, hex: String, context: ModelContext) throws {
        paint.name = name
        paint.brand = brand
        paint.hex = hex.uppercased()
        try context.save()
        Logger.paint.info("Updated paint: \(paint.displayName)")
    }
}

enum PaintLibraryError: LocalizedError {
    case cannotDeleteCataloguePaint

    var errorDescription: String? {
        switch self {
        case .cannotDeleteCataloguePaint:
            return "Catalogue paints cannot be deleted."
        }
    }
}
