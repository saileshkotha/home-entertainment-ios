import SwiftUI

struct HomeView: View {
    @Environment(DownloadsViewModel.self) private var downloadsVM

    private struct MenuItem {
        let label: String
        let description: String
        let icon: String
        let tab: AppTab
        let color: Color
    }

    private let menuItems: [MenuItem] = [
        MenuItem(label: "Explore", description: "Search and browse movies & TV series", icon: "magnifyingglass", tab: .explore, color: Theme.explore),
        MenuItem(label: "TV", description: "Live channels and catch up in one place", icon: "tv", tab: .tv, color: Theme.tv),
        MenuItem(label: "Downloads", description: "View and manage Plex downloads", icon: "arrow.down.circle", tab: .downloads, color: Theme.downloads),
    ]

    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Array(menuItems.enumerated()), id: \.offset) { _, item in
                        menuCard(item)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func menuCard(_ item: MenuItem) -> some View {
        Button {
            selectedTab = item.tab
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(item.color, in: .rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if item.tab == .downloads && downloadsVM.activeCount > 0 {
                            Text("\(downloadsVM.activeCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(item.color, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .glassEffect(Theme.interactiveGlass, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
