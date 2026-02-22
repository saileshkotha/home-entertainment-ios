import SwiftUI

struct MediaCardView: View {
    let movie: Movie

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                CoverImageView(
                    coverPath: movie.cover,
                    categoryId: movie.category.id,
                    movieName: movie.name
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .aspectRatio(2/3, contentMode: .fit)

            VStack(alignment: .leading, spacing: 2) {
                Text(movie.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if movie.year > 0 {
                    Text(String(movie.year))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .clipShape(.rect(cornerRadius: 10))
        .glassEffect(in: .rect(cornerRadius: 10))
    }
}
