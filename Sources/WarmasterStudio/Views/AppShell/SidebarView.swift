import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label(item.rawValue, systemImage: item.systemImage)
                .tag(item)
        }
        .navigationTitle("Warmaster Studio")
        .listStyle(.sidebar)
    }
}
