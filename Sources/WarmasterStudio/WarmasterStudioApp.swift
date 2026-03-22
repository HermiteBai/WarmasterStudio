import SwiftUI
import SwiftData

@main
struct WarmasterStudioApp: App {
    let container: ModelContainer

    init() {
        do {
            // P3-CK-02: ModelConfiguration ready for CloudKit.
            // TODO: Replace with CloudKit container ID: "iCloud.com.yourteam.WarmasterStudio"
            // When adding CloudKit support, use:
            //   ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourteam.WarmasterStudio"))
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let schema = Schema([
                Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
                Paint.self, PaintRecipe.self, RecipeStep.self, RecipePin.self,
                StageHistoryEntry.self
            ])
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

        Settings {
            SettingsView()
        }
    }
}
