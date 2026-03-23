import SwiftUI
import SwiftData

@main
struct WarmasterStudioApp: App {
    let container: ModelContainer

    init() {
        do {
            // Resolve a stable store URL inside the app's Application Support directory.
            // Using an explicit URL prevents SwiftData from resolving to an ephemeral
            // temp location in non-sandboxed debug builds, which would wipe all data
            // on every launch.
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let storeDir = appSupport.appendingPathComponent("com.warmasterstudio.app",
                                                              isDirectory: true)
            try FileManager.default.createDirectory(at: storeDir,
                                                    withIntermediateDirectories: true)
            let storeURL = storeDir.appendingPathComponent("WarmasterStudio.store")

            let schema = Schema([
                Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
                Paint.self, PaintRecipe.self, RecipeStep.self, RecipePin.self,
                StageHistoryEntry.self
            ])
            // P3-CK-02: When adding CloudKit, replace url: with:
            //   ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourteam.WarmasterStudio"))
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)

    }
}
