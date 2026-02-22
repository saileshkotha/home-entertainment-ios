import SwiftUI

enum AppTab: Hashable {
    case home, explore, tv, downloads
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @Environment(DownloadsViewModel.self) private var downloadsVM

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView(selectedTab: $selectedTab)
            }

            Tab("Explore", systemImage: "magnifyingglass", value: .explore) {
                ExploreView()
            }

            Tab("TV", systemImage: "tv.fill", value: .tv) {
                TVView()
            }

            Tab("Downloads", systemImage: "arrow.down.circle.fill", value: .downloads) {
                DownloadsView()
            }
            .badge(downloadsVM.activeCount)
        }
    }
}
