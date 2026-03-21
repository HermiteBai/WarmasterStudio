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
                // Count projects that have at least one model in this stage
                let projectsInStage = Set(
                    filteredRecords
                        .filter { $0.currentStageId == stage.id }
                        .map(\.projectId)
                )
                count = projectsInStage.count
            }
            return StageProgressRow(
                id: stage.id,
                stageName: stage.name,
                position: stage.position,
                count: count,
                total: total
            )
        }
    }

    private var doneRow: StageProgressRow? {
        rows.last
    }

    private var donePercentage: Double {
        doneRow?.percentage ?? 0
    }

    private var totalCount: Int {
        rows.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header controls
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

            Divider()

            // Done percentage hero
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(donePercentage.formatted(.percent.precision(.fractionLength(1))))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                Spacer()
                Gauge(value: donePercentage, in: 0...1) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircular)
                .tint(.green)
                .frame(width: 60)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            // Stage table
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
                            .frame(width: 120, alignment: .leading)

                        ProgressView(value: row.percentage)
                            .tint(row.stageName.lowercased().contains("done") ? .green : .accentColor)

                        Text("\(row.count)")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 40, alignment: .trailing)

                        Text(row.percentage.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)

                Divider()
                HStack {
                    Text("Total")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(totalCount)")
                        .font(.subheadline.monospacedDigit().bold())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Progress")
    }
}
