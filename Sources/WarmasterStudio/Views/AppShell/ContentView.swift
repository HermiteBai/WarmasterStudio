import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: SidebarItem? = .kanban

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            switch selectedItem {
            case .kanban:
                KanbanBoardView()
            case .progress:
                ProgressDashboardView()
            case .collections:
                CollectionsView()
            case .paints:
                PaintLibraryView()
            case .recipes:
                RecipeLibraryView()
            case .statistics:
                StatisticsView()
            case .imageLibrary:
                ImageLibraryView()
            case .settings:
                SettingsView()
            case nil:
                EmptyStateView(
                    title: "Select a Section",
                    subtitle: "Choose an item from the sidebar to get started.",
                    systemImage: "sidebar.left"
                )
            }
        }
        .preferredColorScheme(.dark)
        .task {
            do {
                try PipelineService.bootstrap(context: modelContext)
            } catch {
                print("Failed to bootstrap pipeline: \(error)")
            }
            do {
                try PaintLibraryService.seedCatalogue(context: modelContext)
            } catch {
                print("Failed to seed paint catalogue: \(error)")
            }
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case kanban      = "Kanban"
    case progress    = "Progress"
    case statistics  = "Statistics"
    case collections = "Collections"
    case paints        = "Paints"
    case recipes       = "Recipes"
    case imageLibrary  = "Image Library"
    case settings      = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .kanban:       return "rectangle.3.group"
        case .progress:     return "chart.bar.fill"
        case .statistics:   return "chart.line.uptrend.xyaxis"
        case .collections:  return "folder.fill"
        case .paints:        return "paintpalette.fill"
        case .recipes:       return "list.bullet.clipboard.fill"
        case .imageLibrary:  return "photo.stack.fill"
        case .settings:      return "gear"
        }
    }
}
