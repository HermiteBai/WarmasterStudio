import Foundation
import SwiftData

@Model
final class Stage {
    var id: UUID
    var name: String
    var position: Int

    @Relationship(inverse: \Pipeline.stages)
    var pipeline: Pipeline?

    init(id: UUID = UUID(), name: String, position: Int) {
        self.id = id
        self.name = name
        self.position = position
    }
}
