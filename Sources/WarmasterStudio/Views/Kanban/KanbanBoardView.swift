import SwiftUI
import SwiftData

struct KanbanBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query private var projects: [Project]
    @Query private var modelRecords: [ModelRecord]
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]

    @State private var showNewProjectSheet = false
    @State private var selectedProject: Project? = nil
    @State private var showDetailPanel = false

    var body: some View {
        HSplitView {
            boardContent
                .frame(minWidth: 400)

            if showDetailPanel {
                detailPanel
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDetailPanel)
        .sheet(isPresented: $showNewProjectSheet) {
            NewProjectSheet()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewProjectSheet = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .background(Color.wmBackground)
    }

    @ViewBuilder
    private var boardContent: some View {
        if stages.isEmpty {
            EmptyStateView(
                title: "No Pipeline Stages",
                subtitle: "Configure your pipeline stages in Settings.",
                systemImage: "square.3.layers.3d"
            )
            .background(Color.wmBackground)
        } else {
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(stages) { stage in
                        KanbanColumnView(
                            stage: stage,
                            cards: cards(for: stage)
                        ) { card in
                            selectCard(card)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.wmBackground)
            .animation(.default, value: modelRecords.count)
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text(selectedProject?.name ?? "Project")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetailPanel = false
                        selectedProject = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.wmBorder)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.wmSurface)

            Divider()

            ScrollView {
                if let project = selectedProject {
                    ProjectDetailView(project: project) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDetailPanel = false
                            selectedProject = nil
                        }
                    }
                }
            }
        }
        .background(Color.wmSurface)
    }

    private func cards(for stage: Stage) -> [KanbanCard] {
        let stageId = stage.id
        let recordsAtStage = modelRecords.filter { $0.currentStageId == stageId }
        let grouped = Dictionary(grouping: recordsAtStage, by: \.projectId)

        return grouped.compactMap { (projectId, records) -> KanbanCard? in
            guard let project = projects.first(where: { $0.id == projectId }) else { return nil }
            let collectionName = project.collectionId.flatMap { cid in
                collections.first { $0.id == cid }?.name
            }
            return KanbanCard(
                id: project.id,
                projectId: project.id,
                stageId: stageId,
                projectName: project.name,
                collectionName: collectionName,
                collectionId: project.collectionId,
                modelCount: records.count,
                linkGroupId: project.linkGroupId
            )
        }
        .sorted { $0.projectName < $1.projectName }
    }

    private func selectCard(_ card: KanbanCard) {
        let projectId = card.projectId
        selectedProject = projects.first { $0.id == projectId }
        showDetailPanel = true
    }
}
