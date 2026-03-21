import Foundation
import SwiftData
import os

struct PaintLibraryService {

    private struct CataloguePaint: Decodable {
        let name: String
        let brand: String
        let hex: String
    }

    /// Syncs catalogue paints with the JSON:
    /// - Inserts entries not yet in the database (matched by brand + name).
    /// - Deletes catalogue entries that are no longer present in the JSON.
    /// - Updates the hex value if it changed for an existing entry.
    static func seedCatalogue(context: ModelContext) throws {
        guard let url = Bundle.main.url(forResource: "paint_catalogue", withExtension: "json") else {
            Logger.paint.error("paint_catalogue.json not found in bundle.")
            return
        }

        let data = try Data(contentsOf: url)
        let catalogue = try JSONDecoder().decode([CataloguePaint].self, from: data)
        let catalogueKeys = Set(catalogue.map { "\($0.brand)|\($0.name)" })

        let existing = try context.fetch(FetchDescriptor<Paint>(predicate: #Predicate { !$0.isUserAdded }))

        // Build a lookup of existing DB entries by brand|name key.
        var existingByKey: [String: Paint] = [:]
        for paint in existing {
            existingByKey["\(paint.brand)|\(paint.name)"] = paint
        }

        // Delete stale entries no longer in the JSON.
        var deleted = 0
        for paint in existing where !catalogueKeys.contains("\(paint.brand)|\(paint.name)") {
            context.delete(paint)
            deleted += 1
        }

        // Insert new entries; update hex if it changed.
        var inserted = 0
        var updated = 0
        for entry in catalogue {
            let key = "\(entry.brand)|\(entry.name)"
            if let existing = existingByKey[key] {
                if existing.hex != entry.hex.uppercased() {
                    existing.hex = entry.hex.uppercased()
                    updated += 1
                }
            } else {
                context.insert(Paint(name: entry.name, brand: entry.brand, hex: entry.hex, isUserAdded: false))
                inserted += 1
            }
        }

        let dirty = inserted > 0 || deleted > 0 || updated > 0
        if dirty {
            try context.save()
            Logger.paint.info("Paint catalogue synced — inserted: \(inserted), deleted: \(deleted), updated: \(updated) (JSON total: \(catalogue.count)).")
        } else {
            Logger.paint.debug("Paint catalogue up to date — no changes.")
        }
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
