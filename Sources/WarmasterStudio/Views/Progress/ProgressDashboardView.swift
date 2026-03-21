import SwiftUI
import SwiftData

enum ProgressGranularity: String, CaseIterable {
    case units = "Units"
    case models = "Models"
}

struct StageProgressRow: Identifiable {
    let id: UUID
    let stageName: String
    let position: Int
    let count: Int
    let total: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
}

struct ProgressDashboardView: View {
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query private var projects: [Project]
    @Query private var modelRecords: [ModelRecord]
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]

    @State private var selectedCollectionId: UUID? = nil
    @State private var granularity: ProgressGranularity = .models

    private var filteredProjects: [Project] {
        guard let cid = selectedCollectionId else { return projects }
        return projects.filter { $0.collectionId == cid }
    }

    private var filteredProjectIds: Set<UUID> {
        Set(filteredProjects.map(\.id))
    }

    private var rows: [StageProgressRow] {
        let filteredRecords = modelRecords.filter { filteredProjectIds.contains($0.projectId) }
        let total: Int
        if granularity == .models {
            total = filteredRecords.count
        } else {
            total = filteredProjects.count
        }

        return stages.map { stage in
            let count: Int
            if granularity == .models {
                count = filteredRecords.filter { $0.currentStageId == stage.id }.count
            } else {
                let projectsInStage = Set(
                    filteredRecords.filter { $0.currentStageId == stage.id }.map(\.projectId)
                )
                count = projectsInStage.count
            }
            return StageProgressRow(id: stage.id, stageName: stage.name, position: stage.position, count: count, total: total)
        }
    }

    private var doneRow: StageProgressRow? { rows.last }
    private var donePercentage: Double { doneRow?.percentage ?? 0 }
    private var totalCount: Int { rows.reduce(0) { $0 + $1.count } }

    var body: some View {
        VStack(spacing: 0) {
            // Filter controls
            HStack(spacing: 16) {
                Picker("Collection", selection: $selectedCollectionId) {
                    Text("All Collections").tag(UUID?.none)
                    ForEach(collections) { col in
                        Text(col.name).tag(Optional(col.id))
                    }
                }
                .frame(maxWidth: 220)

                Picker("", selection: $granularity) {
                    ForEach(ProgressGranularity.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.wmSurface)

            Divider().overlay(Color.wmBorder)

            // Done hero
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DONE")
                        .font(.caption.bold())
                        .foregroundStyle(Color.wmPrimary)
                        .kerning(1.5)
                    Text(donePercentage.formatted(.percent.precision(.fractionLength(1))))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Gauge(value: donePercentage, in: 0...1) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Color.wmPrimary)
                .scaleEffect(1.6)
                .shadow(color: Color.wmPrimary.opacity(0.4), radius: 8)
                .frame(width: 80, height: 80)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.wmBackground)

            Divider().overlay(Color.wmBorder)

            // Stage rows
            if rows.isEmpty {
                EmptyStateView(
                    title: "No Data",
                    subtitle: "Create some projects to see progress.",
                    systemImage: "chart.bar"
                )
            } else {
                List(rows) { row in
                    HStack(spacing: 12) {
                        Text(row.stageName)
                            .font(.subheadline)
                            .frame(width: 110, alignment: .leading)
                            .foregroundStyle(.primary)

                        // Gradient progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.wmBorder.opacity(0.4))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.wmPrimary, Color.wmAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, geo.size.width * row.percentage), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(row.count)")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 36, alignment: .trailing)
                            .foregroundStyle(.primary)

                        Text(row.percentage.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.wmBackground)
                }
                .listStyle(.plain)
                .background(Color.wmBackground)

                Divider().overlay(Color.wmBorder)
                HStack {
                    Text("Total")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(totalCount)")
                        .font(.subheadline.monospacedDigit().bold())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.wmSurface)
            }
        }
        .navigationTitle("Progress")
        .background(Color.wmBackground)
    }
}
