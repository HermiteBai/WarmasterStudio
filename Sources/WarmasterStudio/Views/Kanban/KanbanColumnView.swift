import SwiftUI
import SwiftData
import os

struct KanbanColumnView: View {
    @Environment(\.modelContext) private var modelContext

    let stage: Stage
    let cards: [KanbanCard]
    var onSelectCard: ((KanbanCard) -> Void)?

    @State private var isDropTargeted = false

    var totalModels: Int { cards.reduce(0) { $0 + $1.modelCount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Text(stage.name)
                    .font(.headline)
                Spacer()
                Text("\(totalModels)")
                    .font(.caption.monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Cards
            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(cards) { card in
                        KanbanCardView(card: card) {
                            onSelectCard?(card)
                        }
                    }

                    if cards.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .foregroundStyle(.tertiary)
                                .font(.title2)
                            Text("Empty")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 260)
        .background(Color(nsColor: .controlBackgroundColor).opacity(isDropTargeted ? 0.8 : 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .dropDestination(for: String.self) { droppedStrings, _ in
            let projectIds = droppedStrings.compactMap { UUID(uuidString: $0) }
            handleDrop(projectIds: projectIds)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }

    private func handleDrop(projectIds: [UUID]) {
        for projectId in projectIds {
            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate { $0.id == projectId }
            )
            guard let project = try? modelContext.fetch(descriptor).first else { continue }

            // Find models NOT already in this stage
            let modelsNotInStage = project.modelRecords.filter { $0.currentStageId != stage.id }

            // Group by source stage and move
            let grouped = Dictionary(grouping: modelsNotInStage, by: \.currentStageId)
            for (sourceStageId, records) in grouped {
                do {
                    try ModelProgressService.moveModels(
                        count: records.count,
                        fromStageId: sourceStageId,
                        toStageId: stage.id,
                        inProject: project,
                        context: modelContext
                    )
                } catch {
                    Logger.kanban.error("Drop move failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
