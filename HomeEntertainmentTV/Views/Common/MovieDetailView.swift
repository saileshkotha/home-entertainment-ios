import SwiftUI

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct MovieDetailView: View {
    let movieId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var vm = TVMovieDetailViewModel()
    @State private var selectedSeasonId: Int?
    @State private var showPlayer = false
    @State private var toast: String?
    @State private var showFullDescription = false
    @State private var isDescriptionTruncated = false
    enum DetailFocus: Hashable { case play, firstSeason }
    @FocusState private var focus: DetailFocus?

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let movie = vm.movie {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        topSection(movie)
                            .padding(.horizontal, 60)
                            .padding(.top, 30)

                        castSection(movie)
                            .padding(.top, 24)

                        if movie.isTvSeries && !vm.seasons.isEmpty {
                            seasonsSection(movie)
                                .padding(.top, 24)
                        }
                    }
                    .padding(.bottom, 60)
                }
                .background {
                    detailBackground()
                }
            } else {
                ContentUnavailableView("Movie not found", systemImage: "film")
            }
        }
        .task { vm.load(movieId: movieId) }
        .onChange(of: vm.isLoading) { _, isLoading in
            if !isLoading, let movie = vm.movie {
                focus = movie.isTvSeries && !vm.seasons.isEmpty ? .firstSeason : .play
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = vm.playURL {
                VideoPlayerView(url: url)
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: .capsule)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toast)
    }

    // MARK: - Top Section

    @ViewBuilder
    private func topSection(_ movie: Movie) -> some View {
        HStack(alignment: .top, spacing: 30) {
            posterView(movie)
            infoPanel(movie)
                .frame(height: 420)
        }
    }

    // MARK: - Poster

    @ViewBuilder
    private func posterView(_ movie: Movie) -> some View {
        Group {
            if let image = vm.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ColorUtils.categoryGradient(for: movie.category.id)
                    .overlay {
                        Text(String(movie.name.prefix(1)).uppercased())
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
            }
        }
        .frame(width: 280, height: 420)
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - Info Panel

    @ViewBuilder
    private func infoPanel(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(movie.name)
                .font(.title3)
                .fontWeight(.bold)

            metadataLine(movie)
                .padding(.top, 2)

            ratingsLine(movie)
                .padding(.top, 2)

            if !movie.description.isEmpty {
                if isDescriptionTruncated {
                    Button {
                        showFullDescription = true
                    } label: {
                        descriptionText(movie)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                } else {
                    descriptionText(movie)
                        .padding(.top, 14)
                }
            }

            Spacer(minLength: 6)

            creditsSection(movie)

            badgesRow(movie)
                .padding(.top, 8)

            if !movie.isTvSeries && !movie.files.isEmpty {
                actionButtons(movie: movie, file: movie.files[0])
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showFullDescription) {
            NavigationStack {
                ScrollView {
                    Text(movie.description)
                        .font(.body)
                        .lineSpacing(5)
                        .padding(40)
                }
                .navigationTitle(movie.name)
            }
        }
    }

    // MARK: - Metadata

    @ViewBuilder
    private func metadataLine(_ movie: Movie) -> some View {
        HStack(spacing: 16) {
            if movie.year > 0 {
                Text(String(movie.year))
            }
            if movie.duration > 0 {
                Text(formatDuration(movie.duration))
            }
            if !movie.age.isEmpty {
                Text(movie.age)
            }
            if !movie.genres.isEmpty {
                Text(movie.genres.map(\.name).joined(separator: ", "))
                    .lineLimit(1)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Ratings

    @ViewBuilder
    private func ratingsLine(_ movie: Movie) -> some View {
        HStack(spacing: 16) {
            if movie.ratingImdb > 0 {
                RatingBarView(label: "IMDb", rating: movie.ratingImdb, maxRating: 10)
            }
            if movie.ratingKinopoisk > 0 {
                RatingBarView(label: "Kinopoisk", rating: movie.ratingKinopoisk, maxRating: 10)
            }
        }
    }

    // MARK: - Credits

    @ViewBuilder
    private func creditsSection(_ movie: Movie) -> some View {
        if !movie.director.isEmpty {
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 4) {
                GridRow {
                    Text("Director")
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)
                    Text(movie.director)
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Badges

    @ViewBuilder
    private func badgesRow(_ movie: Movie) -> some View {
        HStack(spacing: 8) {
            if let quality = movie.files.first?.quality {
                badgePill(quality.name, subtitle: "\(quality.code)p")
            }
            if let lang = movie.files.first?.languages.first {
                badgePill(LanguageMap.name(for: lang), subtitle: nil)
            }
            badgePill(movie.isTvSeries ? "Series" : "Movie", subtitle: nil)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(movie: Movie, file: MediaFile) -> some View {
        HStack(spacing: 14) {
            Button {
                vm.play(movieId: movie.id, fileId: file.id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if vm.playURL != nil { showPlayer = true }
                }
            } label: {
                Label("Play", systemImage: "play.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(minWidth: 110)
            }
            .focused($focus, equals: .play)
            .disabled(vm.isLoadingLink)

            Button {
                vm.downloadToPlex(
                    movieId: movie.id,
                    fileId: file.id,
                    fileName: FileNameFormatter.movieFileName(name: movie.name, year: movie.year)
                )
                showToast("Download started")
            } label: {
                Label("Download to Plex", systemImage: "arrow.down.to.line")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(minWidth: 110)
            }
            .disabled(vm.isDownloading)
        }
    }

    // MARK: - Cast

    @ViewBuilder
    private func castSection(_ movie: Movie) -> some View {
        let actors = movie.actors
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if !actors.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Cast & Crew")
                    .padding(.horizontal, 60)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if !movie.director.isEmpty {
                            castPill(name: movie.director, role: "Director")
                        }
                        ForEach(Array(actors.prefix(20).enumerated()), id: \.offset) { _, actor in
                            castPill(name: actor, role: nil)
                        }
                    }
                    .padding(.horizontal, 60)
                }
            }
        }
    }

    private func castPill(name: String, role: String?) -> some View {
        Button {} label: {
            VStack(spacing: 3) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let role {
                    Text(role)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Seasons

    @ViewBuilder
    private func seasonsSection(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Seasons")
                .padding(.horizontal, 60)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(vm.seasons) { season in
                        seasonButton(season, movieId: movie.id)
                    }
                }
                .padding(.horizontal, 60)
            }
            .focusSection()

            if let seasonId = selectedSeasonId {
                episodesList(seriesId: movie.id, seriesName: movie.name, seasonId: seasonId)
            }
        }
        .onAppear {
            if selectedSeasonId == nil, let first = vm.seasons.first {
                selectedSeasonId = first.id
                vm.loadEpisodes(seriesId: movie.id, seasonId: first.id)
            }
        }
    }

    @ViewBuilder
    private func seasonButton(_ season: Season, movieId: Int) -> some View {
        let isSelected = selectedSeasonId == season.id
        let isFirst = vm.seasons.first?.id == season.id
        Button {
            selectedSeasonId = season.id
            vm.loadEpisodes(seriesId: movieId, seasonId: season.id)
        } label: {
            VStack(spacing: 3) {
                Text("Season \(season.number)")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                Text(season.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 140)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
        .if(isFirst) { $0.focused($focus, equals: .firstSeason) }
        .if(isSelected) { $0.buttonStyle(.borderedProminent).tint(Theme.accent) }
        .if(!isSelected) { $0.buttonStyle(.bordered) }
    }

    // MARK: - Episodes

    @ViewBuilder
    private func episodesList(seriesId: Int, seriesName: String, seasonId: Int) -> some View {
        if let episodes = vm.episodesBySeasonId[seasonId] {
            let season = vm.seasons.first { $0.id == seasonId }
            let sorted = episodes.sorted { $0.number > $1.number }

            VStack(spacing: 2) {
                ForEach(sorted) { episode in
                    HStack(spacing: 14) {
                        Text("E\(String(format: "%02d", episode.number))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                            .fixedSize()

                        VStack(alignment: .leading, spacing: 1) {
                            Text(episode.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let lang = episode.files.first?.languages.first {
                                Text(LanguageMap.name(for: lang))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if !episode.files.isEmpty {
                            Button {
                                vm.play(movieId: seriesId, fileId: episode.files[0].id)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if vm.playURL != nil { showPlayer = true }
                                }
                            } label: {
                                Label("Play", systemImage: "play.fill")
                            }
                            .disabled(vm.isLoadingLink)

                            Button {
                                vm.downloadToPlex(
                                    movieId: seriesId,
                                    fileId: episode.files[0].id,
                                    fileName: FileNameFormatter.episodeFileName(
                                        seriesName: seriesName,
                                        seasonNumber: season?.number ?? 1,
                                        episodeNumber: episode.number,
                                        episodeName: episode.name,
                                        language: episode.files[0].languages.first
                                    )
                                )
                                showToast("Download started")
                            } label: {
                                Label("Download", systemImage: "arrow.down.to.line")
                            }
                            .disabled(vm.isDownloading)
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 10)

                    Divider()
                        .padding(.horizontal, 60)
                }
            }
            .focusSection()
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(40)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailBackground() -> some View {
        ZStack {
            if let image = vm.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(1.15)
                    .blur(radius: 55)
                    .overlay(
                        LinearGradient(
                            colors: [dominantBackdropColor().opacity(0.45), .black.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                Color.black
            }

            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.55), .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [.clear, .black.opacity(0.45)],
                center: .center,
                startRadius: 180,
                endRadius: 1200
            )
        }
        .ignoresSafeArea()
    }

    private func dominantBackdropColor() -> Color {
        if let dominant = vm.dominantColor {
            return Color(
                red: Double(dominant.red),
                green: Double(dominant.green),
                blue: Double(dominant.blue)
            )
        }
        return .black
    }

    private func descriptionText(_ movie: Movie) -> some View {
        Text(movie.description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineSpacing(3)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .background {
                Text(movie.description)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { fullHeight in
                        isDescriptionTruncated = fullHeight > 80
                    }
            }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }

    private func badgePill(_ title: String, subtitle: String?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private func showToast(_ message: String) {
        toast = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if toast == message { toast = nil }
        }
    }
}
