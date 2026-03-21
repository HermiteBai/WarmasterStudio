import Foundation
import SwiftData

@Model
final class Paint {
    var id: UUID
    var name: String
    var brand: String
    var hex: String       // 6-char hex, no #, uppercase e.g. "1C1C1E"
    var isUserAdded: Bool // false = catalogue seed, true = user-defined
    var createdAt: Date

    // derived
    var displayName: String { "\(brand) – \(name)" }

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        hex: String,
        isUserAdded: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.hex = hex.uppercased()
        self.isUserAdded = isUserAdded
        self.createdAt = createdAt
    }
}
