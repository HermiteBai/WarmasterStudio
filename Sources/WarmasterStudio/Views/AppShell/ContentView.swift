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
            // Purge history entries orphaned by previously deleted projects.
            purgeOrphanedHistoryEntries()
        }
    }
}

// MARK: - Helpers

extension ContentView {
    /// Removes StageHistoryEntry rows whose projectId no longer corresponds to
    /// any existing Project. These are left behind when projects are deleted
    /// without the cascade fix (pre-1.1 data).
    private func purgeOrphanedHistoryEntries() {
        guard let existingIds = try? modelContext.fetch(FetchDescriptor<Project>()).map(\.id) else { return }
        let liveIds = Set(existingIds)
        guard let allEntries = try? modelContext.fetch(FetchDescriptor<StageHistoryEntry>()) else { return }
        let orphans = allEntries.filter { !liveIds.contains($0.projectId) }
        guard !orphans.isEmpty else { return }
        orphans.forEach { modelContext.delete($0) }
        try? modelContext.save()
        print("Purged \(orphans.count) orphaned StageHistoryEntry record(s).")
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
        }
    }
}
