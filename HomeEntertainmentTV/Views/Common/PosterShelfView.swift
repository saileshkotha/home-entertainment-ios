import SwiftUI

struct PosterShelfView: View {
    let title: String
    let movies: [Movie]
    let onSelect: (Movie) -> Void
    var onSeeAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if let onSeeAll {
                    Button("See All") { onSeeAll() }
                        .font(.callout)
                }
            }
            .padding(.horizontal, 60)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(movies) { movie in
                        PosterCardView(movie: movie) {
                            onSelect(movie)
                        }
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
            }
        }
    }
}
