import Foundation

public final class Pipeline: Identifiable {
    public let id: UUID
    public var stages: [Stage]

    public init(id: UUID = UUID()) {
        self.id = id
        self.stages = []
    }
}
