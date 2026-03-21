import SwiftUI
import SwiftData

struct PipelineSettingsView: View {
    @Query private var pipelines: [Pipeline]

    var pipeline: Pipeline? { pipelines.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pipeline Stages")
                .font(.headline)
            if let pipeline {
                let sorted = pipeline.stages.sorted { $0.position < $1.position }
                List(sorted, id: \.id) { stage in
                    Text(stage.name)
                }
            } else {
                Text("No pipeline configured.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
