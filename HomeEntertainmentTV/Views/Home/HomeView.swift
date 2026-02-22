import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @Environment(DownloadsViewModel.self) private var downloadsVM
    @State private var selectedMovie: Movie?
    @State private var heroIndex = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    if !vm.heroMovies.isEmpty {
                        heroCarousel
                    }

                    if !vm.heroMovies.isEmpty {
                        PosterShelfView(
                            title: "Recently Added",
                            movies: vm.heroMovies,
                            onSelect: { selectedMovie = $0 }
                        )
                    }

                    if !vm.favoriteChannels.isEmpty {
                        favoriteChannelsSection
                    }

                    if downloadsVM.activeCount > 0 {
                        activeDownloadsSection
                    }

                    ForEach(vm.shelves) { shelf in
                        PosterShelfView(
                            title: shelf.name,
                            movies: shelf.movies,
                            onSelect: { selectedMovie = $0 }
                        )
                    }
                }
                .padding(.vertical, 40)
            }
            .navigationDestination(item: $selectedMovie) { movie in
                MovieDetailView(movieId: movie.id)
            }
        }
        .onAppear {
            vm.load()
            downloadsVM.startPolling()
        }
        .onDisappear {
            downloadsVM.stopPolling()
        }
    }

    // MARK: - Hero Carousel

    private var heroCarousel: some View {
        TabView(selection: $heroIndex) {
            ForEach(Array(vm.heroMovies.enumerated()), id: \.element.id) { index, movie in
                Button {
                    selectedMovie = movie
                } label: {
                    heroCard(movie)
                }
                .buttonStyle(.card)
                .tag(index)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 460)
        .padding(.horizontal, 40)
    }

    private func heroCard(_ movie: Movie) -> some View {
        ZStack(alignment: .bottomLeading) {
            CoverImageView(
                coverPath: movie.cover,
                categoryId: movie.category.id,
                movieName: movie.name
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.7), .black.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    if movie.year > 0 {
                        Text(String(movie.year))
                    }
                    if movie.duration > 0 {
                        let h = movie.duration / 3600
                        let m = (movie.duration % 3600) / 60
                        Text(h > 0 ? "\(h)h \(m)m" : "\(m)m")
                    }
                    if let quality = movie.files.first?.quality {
                        Text(quality.width >= 3840 ? "4K" : quality.width >= 1920 ? "HD" : "\(quality.code)p")
                            .fontWeight(.semibold)
                    }
                    Text(movie.genres.prefix(2).map(\.name).joined(separator: ", "))
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .padding(30)
        }
        .clipShape(.rect(cornerRadius: 16))
    }

    // MARK: - Favorite Channels

    private var favoriteChannelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Channels")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 60)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(vm.favoriteChannels) { channel in
                        VStack(spacing: 6) {
                            Image(systemName: "tv.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.tv)
                            Text(channel.name)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .lineLimit(1)
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
                        .frame(width: 160)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 60)
            }
        }
    }

    // MARK: - Active Downloads

    private var activeDownloadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Downloading Now")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("\(downloadsVM.activeCount) active")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 60)

            VStack(spacing: 8) {
                ForEach(downloadsVM.downloads.filter(\.isActive).prefix(3)) { download in
                    HStack(spacing: 16) {
                        Text(download.displayName)
                            .font(.callout)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Spacer()

                        ProgressView(value: download.percentCompleted, total: 100)
                            .frame(width: 200)

                        Text("\(Int(download.percentCompleted))%")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 60)
        }
    }
}
