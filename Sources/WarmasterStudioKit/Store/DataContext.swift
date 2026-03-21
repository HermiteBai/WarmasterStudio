import Foundation

/// In-memory store that mirrors the SwiftData ModelContext API for testing.
public final class DataContext {
    private var _pipelines: [UUID: Pipeline] = [:]
    private var _stages: [UUID: Stage] = [:]
    private var _collections: [UUID: WMCollection] = [:]
    private var _projects: [UUID: Project] = [:]
    private var _modelRecords: [UUID: ModelRecord] = [:]

    public init() {}

    // MARK: - Insert

    public func insert(_ pipeline: Pipeline) { _pipelines[pipeline.id] = pipeline }
    public func insert(_ stage: Stage) { _stages[stage.id] = stage }
    public func insert(_ collection: WMCollection) { _collections[collection.id] = collection }
    public func insert(_ project: Project) { _projects[project.id] = project }
    public func insert(_ record: ModelRecord) { _modelRecords[record.id] = record }

    // MARK: - Delete

    public func delete(_ pipeline: Pipeline) { _pipelines.removeValue(forKey: pipeline.id) }
    public func delete(_ stage: Stage) { _stages.removeValue(forKey: stage.id) }
    public func delete(_ collection: WMCollection) { _collections.removeValue(forKey: collection.id) }
    public func delete(_ project: Project) {
        // Cascade: remove all ModelRecords belonging to this project
        for record in project.modelRecords {
            _modelRecords.removeValue(forKey: record.id)
        }
        _projects.removeValue(forKey: project.id)
    }
    public func delete(_ record: ModelRecord) { _modelRecords.removeValue(forKey: record.id) }

    // MARK: - Save (no-op for in-memory store)

    public func save() throws {}

    // MARK: - Fetch

    public func fetchPipelines() -> [Pipeline] { Array(_pipelines.values) }
    public func fetchStages() -> [Stage] { Array(_stages.values) }
    public func fetchCollections() -> [WMCollection] { Array(_collections.values) }
    public func fetchProjects(where predicate: ((Project) -> Bool)? = nil) -> [Project] {
        let all = Array(_projects.values)
        guard let predicate else { return all }
        return all.filter(predicate)
    }
    public func fetchModelRecords(where predicate: ((ModelRecord) -> Bool)? = nil) -> [ModelRecord] {
        let all = Array(_modelRecords.values)
        guard let predicate else { return all }
        return all.filter(predicate)
    }
}
