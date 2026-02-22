import SwiftUI

enum TVAppTab: Hashable {
    case explore, liveTV, downloads
}

struct ContentView: View {
    @State private var selectedTab: TVAppTab = .explore
    @State private var selectedMovie: Movie?
    @Environment(DownloadsViewModel.self) private var downloadsVM

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "magnifyingglass", value: .explore) {
                SearchView(selectedMovie: $selectedMovie)
            }

            Tab("Live TV", systemImage: "tv.fill", value: .liveTV) {
                LiveTVView()
            }

            Tab("Downloads", systemImage: "arrow.down.circle.fill", value: .downloads) {
                DownloadsView()
            }
        }
        .onExitCommand(perform: selectedMovie != nil ? {
            selectedMovie = nil
        } : nil)
    }
}
