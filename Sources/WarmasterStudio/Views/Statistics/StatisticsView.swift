import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var allEntries: [StageHistoryEntry]
    @Query(sort: \Stage.position) private var stages: [Stage]
    @Query(sort: \WMCollection.name) private var collections: [WMCollection]

    @State private var selectedCollectionId: UUID? = nil

    private var finalStageId: UUID? { stages.last?.id }

    private var summary: VelocityService.VelocitySummary? {
        guard let finalId = finalStageId else { return nil }
        return VelocityService.compute(
            entries: allEntries,
            stageOrder: stages,
            collectionId: selectedCollectionId,
            finalStageId: finalId
        )
    }

    private var hasData: Bool {
        !allEntries.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack(spacing: 16) {
                Picker("Collection", selection: $selectedCollectionId) {
                    Text("All Collections").tag(UUID?.none)
                    ForEach(collections) { col in
                        Text(col.name).tag(Optional(col.id))
                    }
                }
                .frame(maxWidth: 220)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.wmSurface)

            Divider().overlay(Color.wmBorder)

            if !hasData {
                EmptyStateView(
                    title: "No History Yet",
                    subtitle: "Move models between stages to start tracking velocity.",
                    systemImage: "chart.bar.xaxis"
                )
            } else if let s = summary {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary cards row
                        HStack(spacing: 16) {
                            summaryCard(
                                title: "WIP",
                                value: "\(s.wip)",
                                subtitle: "models in progress",
                                systemImage: "gearshape.2.fill"
                            )
                            summaryCard(
                                title: "Weekly Rate",
                                value: String(format: "%.1f", s.weeklyRate),
                                subtitle: "models/week",
                                systemImage: "speedometer"
                            )
                            summaryCard(
                                title: "Last 30 Days",
                                value: "\(s.completedLast30Days)",
                                subtitle: "completed",
                                systemImage: "checkmark.seal.fill"
                            )
                            summaryCard(
                                title: "Last 7 Days",
                                value: "\(s.completedLast7Days)",
                                subtitle: "completed",
                                systemImage: "calendar.badge.checkmark"
                            )
                        }
                        .padding(.horizontal, 20)

                        // Projected finish
                        if let days = s.projectedDaysToFinish {
                            HStack {
                                Image(systemName: "flag.checkered")
                                    .foregroundStyle(Color.wmPrimary)
                                Text("Projected to finish remaining WIP in ")
                                    .foregroundStyle(.secondary)
                                + Text(String(format: "%.0f days", days))
                                    .bold()
                                    .foregroundStyle(Color.wmPrimary)
                                Spacer()
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.wmSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }

                        // Avg days per stage bar chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Average Days per Stage")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)

                            let nonZeroStats = s.stageStats.filter { $0.sampleCount > 0 }
                            if nonZeroStats.isEmpty {
                                Text("No completed stage transitions yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            } else {
                                Chart(s.stageStats, id: \.stageId) { stat in
                                    BarMark(
                                        x: .value("Stage", stat.stageName),
                                        y: .value("Avg Days", stat.averageDays)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.wmPrimary, Color.wmAccent],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(4)
                                    .annotation(position: .top) {
                                        if stat.averageDays > 0 {
                                            Text(String(format: "%.1fd", stat.averageDays))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisValueLabel()
                                            .font(.caption)
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(values: .automatic) { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let d = value.as(Double.self) {
                                                Text(String(format: "%.0fd", d))
                                                    .font(.caption2)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color.wmSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 20)

                        // Per-stage sample count table
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Sample Counts")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                            ForEach(s.stageStats, id: \.stageId) { stat in
                                HStack {
                                    Text(stat.stageName)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if stat.sampleCount > 0 {
                                        Text(String(format: "%.1f d avg", stat.averageDays))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("(\(stat.sampleCount))")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(Color.wmAccent)
                                    } else {
                                        Text("no data")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(stat.sampleCount > 0
                                    ? "\(stat.stageName): \(String(format: "%.1f", stat.averageDays)) day average, \(stat.sampleCount) samples"
                                    : "\(stat.stageName): no data"
                                )

                                if stat.stageId != s.stageStats.last?.stageId {
                                    Divider()
                                        .padding(.leading, 16)
                                        .overlay(Color.wmBorder)
                                }
                            }
                        }
                        .background(Color.wmSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 20)
                }
                .background(Color.wmBackground)
            }
        }
        .navigationTitle("Statistics")
        .background(Color.wmBackground)
    }

    @ViewBuilder
    private func summaryCard(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.wmPrimary)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .kerning(0.5)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.wmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) \(subtitle)")
    }
}
