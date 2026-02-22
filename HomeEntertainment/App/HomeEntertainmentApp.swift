import SwiftUI

@main
struct HomeEntertainmentApp: App {
    @State private var downloadsVM = DownloadsViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloadsVM)
                .tint(.indigo)
        }
    }
}
