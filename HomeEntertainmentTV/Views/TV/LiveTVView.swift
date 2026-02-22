import SwiftUI

struct LiveTVView: View {
    @State private var vm = LiveTVViewModel()
    @State private var selectedChannel: TvChannel?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    searchField
                        .padding(.horizontal, 60)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    filterBar
                        .padding(.horizontal, 60)
                        .padding(.bottom, 30)

                    if !vm.favoriteChannels.isEmpty {
                        Text("Favorites")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 60)
                            .padding(.bottom, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(vm.favoriteChannels) { channel in
                                    channelCard(channel)
                                        .frame(width: 300)
                                }
                            }
                            .padding(.horizontal, 60)
                        }
                        .focusSection()
                        .padding(.bottom, 40)
                    }

                    Text("All Channels")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 16)

                    if vm.filteredChannels.isEmpty {
                        ContentUnavailableView("No channels found", systemImage: "tv")
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(vm.filteredChannels) { channel in
                                channelCard(channel)
                            }
                        }
                        .focusSection()
                        .padding(.horizontal, 60)
                        .padding(.bottom, 40)
                    }
                }
            }
            .onChange(of: vm.searchText) { _, _ in vm.filterChannels() }
            .onChange(of: vm.selectedCategoryId) { _, _ in vm.filterChannels() }
            .navigationDestination(item: $selectedChannel) { channel in
                ChannelDetailView(vm: vm, channel: channel)
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search channels...", text: $vm.searchText)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 20) {
            Menu {
                Picker("Category", selection: $vm.selectedCategoryId) {
                    Text("All categories").tag("all")
                    ForEach(vm.channelCategories, id: \.id) { cat in
                        Text(cat.name).tag(String(cat.id))
                    }
                }
            } label: {
                dropdownLabel(
                    vm.channelCategories.first(where: { String($0.id) == vm.selectedCategoryId })?.name ?? "All categories"
                )
            }

            Spacer()
        }
    }

    private func dropdownLabel(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .fontWeight(.semibold)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }

    // MARK: - Channel Card

    private func channelCard(_ channel: TvChannel) -> some View {
        Button {
            vm.selectChannel(channel)
            selectedChannel = channel
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "tv.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.tv)

                    Spacer()

                    HStack(spacing: 6) {
                        if vm.isFavorite(channel) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        if channel.hasArchive {
                            Text("Archive")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple, in: Capsule())
                        }
                    }
                }

                Spacer()

                Text(channel.name)
                    .font(.callout)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(channel.genre.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        }
        .buttonStyle(.card)
        .contextMenu {
            Button {
                vm.toggleFavorite(channel)
            } label: {
                Label(
                    vm.isFavorite(channel) ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: vm.isFavorite(channel) ? "star.slash" : "star"
                )
            }
        }
    }
}

// MARK: - Channel Detail

private struct ChannelDetailView: View {
    var vm: LiveTVViewModel
    let channel: TvChannel
    @State private var showPlayer = false
    @State private var showCatchUp = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(channel.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(channel.genre.name)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                        Text("LIVE")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Actions")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.tv)

                    HStack(spacing: 16) {
                        Button {
                            vm.fetchLiveLink()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if vm.activeLink != nil { showPlayer = true }
                            }
                        } label: {
                            Label(
                                vm.isLoadingLink ? "Loading..." : "Watch Live",
                                systemImage: "play.fill"
                            )
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(minWidth: 200)
                        }
                        .disabled(vm.isLoadingLink)

                        Button {
                            let key = "live-\(channel.id)"
                            if vm.activeLink == nil {
                                vm.fetchLiveLink()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                vm.downloadToPlex(
                                    rowKey: key,
                                    fileName: FileNameFormatter.liveFileName(channelName: channel.name)
                                )
                            }
                        } label: {
                            Label("Download to Plex", systemImage: "arrow.down.to.line")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(minWidth: 200)
                        }
                        .disabled(vm.isDownloading)

                        if channel.hasArchive {
                            Button {
                                showCatchUp = true
                                vm.loadGuide()
                            } label: {
                                Label("Catch Up", systemImage: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 200)
                            }
                        }
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 16))

                if channel.hasArchive {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.purple)
                        Text("\(channel.archiveRange ?? 7)-day archive available")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = vm.error {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .navigationDestination(isPresented: $showCatchUp) {
            CatchUpView(vm: vm, channel: channel)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let link = vm.activeLink, let url = URL(string: link.url) {
                VideoPlayerView(url: url)
            }
        }
    }
}
