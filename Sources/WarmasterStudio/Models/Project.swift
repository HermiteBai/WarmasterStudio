import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var modelCount: Int
    var collectionId: UUID?
    var linkGroupId: UUID?
    var notes: String?
    var boxArtImagePath: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var modelRecords: [ModelRecord]

    init(
        id: UUID = UUID(),
        name: String,
        modelCount: Int,
        collectionId: UUID? = nil,
        linkGroupId: UUID? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.modelCount = modelCount
        self.collectionId = collectionId
        self.linkGroupId = linkGroupId
        self.notes = notes
        self.createdAt = createdAt
        self.modelRecords = []
    }
}
