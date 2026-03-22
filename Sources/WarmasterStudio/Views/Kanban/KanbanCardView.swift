import SwiftUI
import SwiftData
import os

struct KanbanCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.position) private var stages: [Stage]

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
        return Color(hue: hue, saturation: 0.8, brightness: 0.9)
    }

    @ViewBuilder
    private var thumbnailStrip: some View {
        if let path = card.boxArtImagePath,
           let url = ImageService.resolveImageURL(relativePath: path),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 80)
                .clipped()
                .overlay(alignment: .topLeading) {
                    // Keep the link-group accent as a left edge stripe on the thumbnail
                    if let accent = linkAccentColor {
                        accent.frame(width: 4)
                    }
                }
                .accessibilityHidden(true)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail strip — shown when box art is available
            thumbnailStrip

            HStack(spacing: 0) {
                // Link group accent bar (only shown when no thumbnail present)
                if card.boxArtImagePath == nil {
                    if let accent = linkAccentColor {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accent)
                            .frame(width: 3)
                            .padding(.vertical, 8)
                            .padding(.leading, 6)
                    } else {
                        Color.clear.frame(width: 9)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Title + model count badge
                    HStack(alignment: .top) {
                        Text(card.projectName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer()
                        Text("\(card.modelCount)")
                            .font(.caption.monospacedDigit().bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.wmAccent.opacity(0.2))
                            .foregroundStyle(Color.wmAccent)
                            .clipShape(Capsule())
                    }

                    if let col = card.collectionName {
                        Label(col, systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Stage navigation
                    HStack(spacing: 6) {
                        Button { moveToPreviousStage() } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title3)
                                .foregroundStyle(isFirstStage ? Color.wmAccent.opacity(0.3) : Color.wmAccent)
                        }
                        .buttonStyle(.plain)
                        .disabled(isFirstStage)
                        .accessibilityLabel(isFirstStage ? "Move back (unavailable)" : "Move one model to previous stage")

                        Spacer()

                        if let idx = currentStageIndex {
                            Text(stages[idx].name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button { moveToNextStage() } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title3)
                                .foregroundStyle(isLastStage ? Color.wmAccent.opacity(0.3) : Color.wmAccent)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLastStage)
                        .accessibilityLabel(isLastStage ? "Move forward (unavailable)" : "Move one model to next stage")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
        }
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.wmSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.wmBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
        .draggable(card.projectId.uuidString)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(card.projectName), \(card.modelCount) model\(card.modelCount == 1 ? "" : "s") at \(stages.first(where: { $0.id == card.stageId })?.name ?? "current stage")")
        .accessibilityHint("Tap to view project details")
    }

    private func moveToPreviousStage() {
        guard let idx = currentStageIndex, idx > 0 else { return }
        moveCard(to: stages[idx - 1])
    }

    private func moveToNextStage() {
        guard let idx = currentStageIndex, idx < stages.count - 1 else { return }
        moveCard(to: stages[idx + 1])
    }

    private func moveCard(to targetStage: Stage) {
        let projectId = card.projectId
        let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.id == projectId })
        guard let project = try? modelContext.fetch(descriptor).first else {
            Logger.kanban.error("Project not found for card move")
            return
        }
        // Capture the records that will move before moving them
        let atSource = project.modelRecords.filter { $0.currentStageId == card.stageId }
        let toMove = Array(atSource.prefix(1))
        let fromStageName = stages.first(where: { $0.id == card.stageId })?.name ?? ""

        do {
            try ModelProgressService.moveModels(
                count: 1,
                fromStageId: card.stageId,
                toStageId: targetStage.id,
                inProject: project,
                context: modelContext
            )
            try StageHistoryService.recordMove(
                records: toMove,
                fromStageId: card.stageId,
                fromStageName: fromStageName,
                toStageId: targetStage.id,
                toStageName: targetStage.name,
                projectId: project.id,
                collectionId: project.collectionId,
                context: modelContext
            )
        } catch {
            Logger.kanban.error("Move failed: \(error.localizedDescription)")
        }
    }
}
