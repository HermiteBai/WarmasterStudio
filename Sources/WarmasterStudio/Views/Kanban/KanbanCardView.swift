import SwiftUI
import SwiftData
import os

struct KanbanCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]

    let card: KanbanCard
    var onSelect: (() -> Void)?

    private var currentStageIndex: Int? {
        stages.firstIndex { $0.id == card.stageId }
    }
    private var isFirstStage: Bool { currentStageIndex == 0 }
    private var isLastStage: Bool {
        guard let idx = currentStageIndex else { return true }
        return idx == stages.count - 1
    }

    private var linkAccentColor: Color? {
        guard let groupId = card.linkGroupId else { return nil }
        let bytes = withUnsafeBytes(of: groupId.uuid) { Array($0) }
        let hue = Double(bytes[0]) / 255.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.85)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Link group accent
            if let accent = linkAccentColor {
                Rectangle()
                    .fill(accent)
                    .frame(width: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Card header row
                HStack {
                    Text(card.projectName)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                    Text("\(card.modelCount)")
                        .font(.caption.monospacedDigit().bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                if let col = card.collectionName {
                    Label(col, systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Navigation buttons
                HStack(spacing: 8) {
                    Button {
                        moveToPreviousStage()
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isFirstStage)

                    Spacer()

                    Button {
                        moveToNextStage()
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isLastStage)
                }
            }
            .padding(10)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
        .draggable(card.projectId.uuidString)
    }

    private func moveToPreviousStage() {
        guard let idx = currentStageIndex, idx > 0 else { return }
        let prevStage = stages[idx - 1]
        moveCard(to: prevStage)
    }

    private func moveToNextStage() {
        guard let idx = currentStageIndex, idx < stages.count - 1 else { return }
        let nextStage = stages[idx + 1]
        moveCard(to: nextStage)
    }

    private func moveCard(to targetStage: Stage) {
        let projectId = card.projectId
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == projectId }
        )
        guard let project = try? modelContext.fetch(descriptor).first else {
            Logger.kanban.error("Project not found for card move")
            return
        }
        do {
            try ModelProgressService.moveModels(
                count: 1,
                fromStageId: card.stageId,
                toStageId: targetStage.id,
                inProject: project,
                context: modelContext
            )
        } catch {
            Logger.kanban.error("Move failed: \(error.localizedDescription)")
        }
    }
}
