import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            PipelineSettingsView()
                .tabItem {
                    Label("Pipeline", systemImage: "square.3.layers.3d")
                }
        }
        .frame(minWidth: 480, minHeight: 380)
        .navigationTitle("Settings")
    }
}
