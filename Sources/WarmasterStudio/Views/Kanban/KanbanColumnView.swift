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

    private var stageHue: Double {
        let hues: [Double] = [0.70, 0.55, 0.10, 0.45, 0.33, 0.02, 0.60, 0.80]
        return hues[min(stage.position, 7)]
    }
    private var stageAccent: Color { Color(hue: stageHue, saturation: 0.7, brightness: 0.85) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(stageAccent)
                    .frame(width: 3, height: 18)

                Text(stage.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(totalModels)")
                    .font(.caption.monospacedDigit().bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.wmPrimary.opacity(0.2))
                    .foregroundStyle(Color.wmPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.wmSurface.opacity(0.6))

            Divider()
                .overlay(Color.wmBorder)

            // Cards
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(cards) { card in
                        KanbanCardView(card: card) {
                            onSelectCard?(card)
                        }
                    }
                    .animation(.default, value: cards)

                    if cards.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundStyle(Color.wmBorder)
                            Text("Drop here")
                                .font(.caption)
                                .foregroundStyle(Color.wmBorder)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    }
                }
                .padding(10)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wmSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.wmPrimary : Color.wmBorder,
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .shadow(
            color: isDropTargeted ? Color.wmPrimary.opacity(0.25) : Color.black.opacity(0.15),
            radius: isDropTargeted ? 8 : 4, x: 0, y: 2
        )
        .dropDestination(for: String.self) { strings, _ in
            handleDrop(projectIdStrings: strings)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.15)) { isDropTargeted = targeted }
        }
    }

    private func handleDrop(projectIdStrings: [String]) {
        for idString in projectIdStrings {
            guard let projectId = UUID(uuidString: idString) else { continue }
            let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.id == projectId })
            guard let project = try? modelContext.fetch(descriptor).first else { continue }

            let modelsNotInStage = project.modelRecords.filter { $0.currentStageId != stage.id }
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
