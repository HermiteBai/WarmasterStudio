import os

extension Logger {
    static let pipeline = Logger(subsystem: "com.warmasterstudio", category: "Pipeline")
    static let stage = Logger(subsystem: "com.warmasterstudio", category: "Stage")
    static let project = Logger(subsystem: "com.warmasterstudio", category: "Project")
    static let kanban = Logger(subsystem: "com.warmasterstudio", category: "Kanban")
    static let collection = Logger(subsystem: "com.warmasterstudio", category: "Collection")
    static let modelProgress = Logger(subsystem: "com.warmasterstudio", category: "ModelProgress")
    static let linkGroup = Logger(subsystem: "com.warmasterstudio", category: "LinkGroup")
    static let image = Logger(subsystem: "com.warmasterstudio", category: "Image")
}
