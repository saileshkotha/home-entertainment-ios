import SwiftUI

struct MediaGridView: View {
    let movies: [Movie]
    let isLoading: Bool
    let isFetchingMore: Bool
    let hasMore: Bool
    let onLoadMore: () -> Void
    let onSelect: (Movie) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 14)
    ]

    var body: some View {
        if isLoading {
            VStack {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if movies.isEmpty {
            ContentUnavailableView("No results found", systemImage: "film")
        } else {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(movies) { movie in
                    MediaCardView(movie: movie)
                        .onTapGesture { onSelect(movie) }
                        .onAppear {
                            if movie.id == movies.last?.id {
                                onLoadMore()
                            }
                        }
                }
            }

            if isFetchingMore {
                ProgressView()
                    .padding()
            } else if hasMore {
                Button("Load More") { onLoadMore() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .tint(Theme.accent)
                    .padding()
            }
        }
    }
}
