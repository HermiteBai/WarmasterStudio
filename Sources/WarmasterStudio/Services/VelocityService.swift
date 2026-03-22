import Foundation
import SwiftData

struct VelocityService {

    struct StageStats {
        let stageId: UUID
        let stageName: String
        let averageDays: Double    // average days spent in this stage
        let sampleCount: Int       // how many completed entries
    }

    struct VelocitySummary {
        let stageStats: [StageStats]          // sorted by pipeline order
        let completedLast30Days: Int          // models that finished in the last 30 days
        let completedLast7Days: Int           // models that finished in the last 7 days
        let weeklyRate: Double                // avg models completed per week (last 4 weeks)
        let wip: Int                          // models currently in progress (not in final stage)
        let projectedDaysToFinish: Double?    // nil if weeklyRate == 0
    }

    /// Compute stats from StageHistoryEntry records.
    /// Pass `collectionId: nil` for all-collections.
    /// `finalStageId` is the last stage in the pipeline (models reaching here are "complete").
    static func compute(
        entries: [StageHistoryEntry],
        stageOrder: [Stage],
        collectionId: UUID?,
        finalStageId: UUID
    ) -> VelocitySummary {
        let filtered = collectionId == nil ? entries : entries.filter { $0.collectionId == collectionId }

        // Per-stage average time (completed entries only)
        var stageStats: [StageStats] = []
        for stage in stageOrder {
            let completed = filtered.filter { $0.stageId == stage.id && $0.leftAt != nil }
            let durations = completed.compactMap { $0.duration }
            let avgDays = durations.isEmpty ? 0 : (durations.reduce(0, +) / Double(durations.count)) / 86400
            stageStats.append(StageStats(
                stageId: stage.id,
                stageName: stage.name,
                averageDays: avgDays,
                sampleCount: durations.count
            ))
        }

        // Completion counts (entries that entered the final stage)
        let now = Date.now
        let last30 = now.addingTimeInterval(-30 * 86400)
        let last7  = now.addingTimeInterval(-7  * 86400)
        let last28 = now.addingTimeInterval(-28 * 86400)

        let finalEntries = filtered.filter { $0.stageId == finalStageId }
        let completed30 = finalEntries.filter { $0.enteredAt >= last30 }.count
        let completed7  = finalEntries.filter { $0.enteredAt >= last7  }.count
        let completed28 = finalEntries.filter { $0.enteredAt >= last28 }.count
        let weeklyRate  = Double(completed28) / 4.0

        // WIP = open entries NOT in the final stage
        let wip = filtered.filter { $0.stageId != finalStageId && $0.leftAt == nil }.count

        let projected: Double? = weeklyRate > 0 ? (Double(wip) / weeklyRate) * 7 : nil

        return VelocitySummary(
            stageStats: stageStats,
            completedLast30Days: completed30,
            completedLast7Days: completed7,
            weeklyRate: weeklyRate,
            wip: wip,
            projectedDaysToFinish: projected
        )
    }
}
