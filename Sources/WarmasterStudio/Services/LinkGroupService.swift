import Foundation
import SwiftData
import os

struct LinkGroupService {

    /// Links two projects together. If one already has a linkGroupId, reuses it; otherwise creates new UUID.
    static func linkProjects(_ a: Project, _ b: Project, context: ModelContext) throws {
        let groupId: UUID
        if let existing = a.linkGroupId ?? b.linkGroupId {
            groupId = existing
            Logger.linkGroup.info("Reusing existing link group \(groupId) for projects '\(a.name)' and '\(b.name)'.")
        } else {
            groupId = UUID()
            Logger.linkGroup.info("Creating new link group \(groupId) for projects '\(a.name)' and '\(b.name)'.")
        }
        a.linkGroupId = groupId
        b.linkGroupId = groupId
        try context.save()
    }

    /// Sets linkGroupId to nil on the project.
    static func unlinkProject(_ project: Project, context: ModelContext) throws {
        Logger.linkGroup.info("Unlinking project '\(project.name)' from group \(project.linkGroupId.map(\.uuidString) ?? "none").")
        project.linkGroupId = nil
        try context.save()
    }
}
