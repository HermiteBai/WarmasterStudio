import Foundation
import SwiftData

@Model
final class Pipeline {
    var id: UUID
    @Relationship(deleteRule: .cascade)
    var stages: [Stage]

    init(id: UUID = UUID()) {
        self.id = id
        self.stages = []
    }
}
