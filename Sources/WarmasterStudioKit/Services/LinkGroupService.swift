import Foundation

public struct LinkGroupService {

    /// Links two projects together. If one already has a linkGroupId, reuses it; otherwise creates new UUID.
    public static func linkProjects(_ a: Project, _ b: Project, context: DataContext) throws {
        let groupId: UUID = a.linkGroupId ?? b.linkGroupId ?? UUID()
        a.linkGroupId = groupId
        b.linkGroupId = groupId
        try context.save()
    }

    /// Sets linkGroupId to nil on the project.
    public static func unlinkProject(_ project: Project, context: DataContext) throws {
        project.linkGroupId = nil
        try context.save()
    }
}
