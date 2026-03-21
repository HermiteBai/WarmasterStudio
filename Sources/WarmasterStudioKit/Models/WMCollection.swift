import Foundation

public final class WMCollection: Identifiable {
    public let id: UUID
    public var name: String
    public var notes: String?
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
    }
}
