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
    @State private var searchText = ""

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
        .searchable(text: $searchText, prompt: "Filter projects")
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
                .keyboardShortcut(.escape, modifiers: [])
                .accessibilityLabel("Close project detail")
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
            guard searchText.isEmpty || project.name.localizedCaseInsensitiveContains(searchText) else { return nil }
            let collectionName = project.collectionId.flatMap { cid in
                collections.first { $0.id == cid }?.name
            }
            // Resolve box-art: own image first, then any linked-group member's image.
            let boxArtPath: String? = project.boxArtImagePath ?? {
                guard let groupId = project.linkGroupId else { return nil }
                return projects.first {
                    $0.id != project.id &&
                    $0.linkGroupId == groupId &&
                    $0.boxArtImagePath != nil
                }?.boxArtImagePath
            }()
            return KanbanCard(
                id: project.id,
                projectId: project.id,
                stageId: stageId,
                projectName: project.name,
                collectionName: collectionName,
                collectionId: project.collectionId,
                modelCount: records.count,
                linkGroupId: project.linkGroupId,
                boxArtImagePath: boxArtPath
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.linkGroupId, rhs.linkGroupId) {
            case (nil, nil):
                return lhs.projectName < rhs.projectName
            case (nil, _):
                return false
            case (_, nil):
                return true
            case (let a?, let b?) where a == b:
                return lhs.projectName < rhs.projectName
            case (let a?, let b?):
                return a.uuidString < b.uuidString
            }
        }
    }

    private func selectCard(_ card: KanbanCard) {
        let projectId = card.projectId
        selectedProject = projects.first { $0.id == projectId }
        showDetailPanel = true
    }
}
