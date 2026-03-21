import SwiftUI
import SwiftData

@main
struct WarmasterStudioApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Pipeline.self, Stage.self, WMCollection.self, Project.self, ModelRecord.self,
                     Paint.self, PaintRecipe.self, RecipeStep.self
            )
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
