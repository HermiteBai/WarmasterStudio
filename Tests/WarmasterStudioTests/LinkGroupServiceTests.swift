import Testing
import Foundation
import SwiftData
@testable import WarmasterStudio

@Suite("LinkGroupService Tests")
struct LinkGroupServiceTests {

    @MainActor
    func makeContainerAndProjects() throws -> (ModelContainer, Project, Project, Project) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
            configurations: config
        )
        let context = container.mainContext
        let pipeline = try PipelineService.bootstrap(context: context)
        let p1 = try ProjectService.createProject(name: "Project 1", modelCount: 1, in: pipeline, context: context)
        let p2 = try ProjectService.createProject(name: "Project 2", modelCount: 1, in: pipeline, context: context)
        let p3 = try ProjectService.createProject(name: "Project 3", modelCount: 1, in: pipeline, context: context)
        return (container, p1, p2, p3)
    }

    @Test("linkProjects assigns same UUID to both")
    @MainActor
    func linkProjects() throws {
        let (container, p1, p2, _) = try makeContainerAndProjects()
        let context = container.mainContext

        try LinkGroupService.linkProjects(p1, p2, context: context)

        #expect(p1.linkGroupId != nil)
        #expect(p1.linkGroupId == p2.linkGroupId)
    }

    @Test("linkProjects with existing group reuses group UUID")
    @MainActor
    func linkProjectsReusesGroup() throws {
        let (container, p1, p2, p3) = try makeContainerAndProjects()
        let context = container.mainContext

        try LinkGroupService.linkProjects(p1, p2, context: context)
        let groupId = p1.linkGroupId!

        try LinkGroupService.linkProjects(p2, p3, context: context)

        #expect(p1.linkGroupId == groupId)
        #expect(p2.linkGroupId == groupId)
        #expect(p3.linkGroupId == groupId)
    }

    @Test("unlinkProject sets linkGroupId to nil")
    @MainActor
    func unlinkProject() throws {
        let (container, p1, p2, _) = try makeContainerAndProjects()
        let context = container.mainContext

        try LinkGroupService.linkProjects(p1, p2, context: context)
        #expect(p1.linkGroupId != nil)

        try LinkGroupService.unlinkProject(p1, context: context)
        #expect(p1.linkGroupId == nil)
        #expect(p2.linkGroupId != nil)
    }
}
