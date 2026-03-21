import Foundation

public final class Project: Identifiable {
    public let id: UUID
    public var name: String
    public var modelCount: Int
    public var collectionId: UUID?
    public var linkGroupId: UUID?
    public var notes: String?
    public var createdAt: Date
    public var modelRecords: [ModelRecord]

    public init(
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
