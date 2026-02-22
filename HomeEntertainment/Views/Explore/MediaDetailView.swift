import SwiftUI

struct MediaDetailView: View {
    let movieId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var vm = MovieDetailViewModel()
    @State private var expandedSeasonId: Int?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let movie = vm.movie {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            heroSection(movie)
                            badgesSection(movie)
                                .padding(.top, 12)

                            if !movie.isTvSeries && !movie.files.isEmpty {
                                ActionButtonsView(
                                    movieId: movie.id,
                                    fileId: movie.files[0].id,
                                    downloadFileName: FileNameFormatter.movieFileName(name: movie.name, year: movie.year)
                                )
                                .padding(.horizontal)
                                .padding(.top, 12)
                            }

                            if !movie.description.isEmpty {
                                descriptionSection(movie)
                                    .padding(.top, 16)
                            }

                            castSection(movie)
                                .padding(.top, 16)

                            if movie.isTvSeries && !vm.seasons.isEmpty {
                                seasonsSection(movie)
                                    .padding(.top, 16)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                } else {
                    ContentUnavailableView("Movie not found", systemImage: "film")
                }
            }
            .navigationTitle(vm.movie?.name ?? "Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { vm.load(movieId: movieId) }
    }

    @ViewBuilder
    private func heroSection(_ movie: Movie) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            Group {
                if let image = vm.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ColorUtils.categoryGradient(for: movie.category.id)
                        .overlay {
                            Text(String(movie.name.prefix(1)).uppercased())
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                }
            }
            .frame(width: 110, height: 165)
            .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.name)
                    .font(.title3)
                    .fontWeight(.bold)

                if movie.year > 0 {
                    Text(String(movie.year))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !movie.director.isEmpty {
                    Label(movie.director, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if movie.duration > 0 {
                    Label(formatDuration(movie.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(Theme.heroGlass, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func badgesSection(_ movie: Movie) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                badge(movie.isTvSeries ? "Series" : "Movie", color: movie.isTvSeries ? .purple : Theme.accent)

                ForEach(movie.genres) { genre in
                    badge(genre.name, color: .purple)
                }

                if let quality = movie.files.first?.quality {
                    badge("\(quality.code)p", color: .teal)
                }

                if let lang = movie.files.first?.languages.first {
                    badge(LanguageMap.name(for: lang), color: .orange)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func descriptionSection(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("About")
            Text(movie.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func castSection(_ movie: Movie) -> some View {
        let actors = movie.actors
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if !actors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Cast")

                FlowLayout(spacing: 6) {
                    ForEach(Array(actors.prefix(12).enumerated()), id: \.offset) { _, actor in
                        Text(actor)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.18), in: Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func seasonsSection(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Seasons")
                .padding(.horizontal)

            ForEach(vm.seasons) { season in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSeasonId == season.id },
                        set: { isExpanded in
                            expandedSeasonId = isExpanded ? season.id : nil
                            if isExpanded {
                                vm.loadEpisodes(seriesId: movie.id, seasonId: season.id)
                            }
                        }
                    )
                ) {
                    episodesList(seriesId: movie.id, seriesName: movie.name, season: season)
                } label: {
                    Text("Season \(season.number) — \(season.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .tint(Theme.accent)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func episodesList(seriesId: Int, seriesName: String, season: Season) -> some View {
        if let episodes = vm.episodesBySeasonId[season.id] {
            let sorted = episodes.sorted { $0.number > $1.number }
            ForEach(sorted) { episode in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("E\(episode.number)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 36, alignment: .leading)
                        Text(episode.name)
                            .font(.caption)
                            .lineLimit(2)
                    }

                    if !episode.files.isEmpty {
                        ActionButtonsView(
                            movieId: seriesId,
                            fileId: episode.files[0].id,
                            downloadFileName: FileNameFormatter.episodeFileName(
                                seriesName: seriesName,
                                seasonNumber: season.number,
                                episodeNumber: episode.number,
                                episodeName: episode.name,
                                language: episode.files[0].languages.first
                            ),
                            compact: true
                        )
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
        } else {
            ProgressView()
                .tint(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(Theme.accent)
            .textCase(.uppercase)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color, in: .capsule)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
