import SwiftUI

@main
struct HomeEntertainmentTVApp: App {
    @State private var downloadsVM = DownloadsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadsVM)
        }
    }
}
