import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label(item.rawValue, systemImage: item.systemImage)
                .tag(item)
                .foregroundStyle(selectedItem == item ? Color.wmPrimary : Color.primary)
        }
        .navigationTitle("Warmaster Studio")
        .listStyle(.sidebar)
        .tint(.wmPrimary)
    }
}
