import Foundation

public final class Stage: Identifiable {
    public let id: UUID
    public var name: String
    public var position: Int
    public weak var pipeline: Pipeline?

    public init(id: UUID = UUID(), name: String, position: Int) {
        self.id = id
        self.name = name
        self.position = position
    }
}
