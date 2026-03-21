import Foundation
import SwiftData

@Model
final class WMCollection {
    var id: UUID
    var name: String
    var notes: String?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
    }
}
