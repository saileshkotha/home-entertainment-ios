import SwiftUI

struct PosterCardView: View {
    let movie: Movie
    let onSelect: () -> Void

    private var qualityLabel: String? {
        guard let q = movie.files.first?.quality else { return nil }
        return q.width >= 3840 ? "4K" : q.width >= 1920 ? "HD" : nil
    }

    private var isNew: Bool {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let addedDate = Date(timeIntervalSince1970: TimeInterval(movie.added))
        return addedDate > sevenDaysAgo
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                posterImage

                VStack(alignment: .leading, spacing: 1) {
                    Text(movie.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if movie.year > 0 {
                            Text(String(movie.year))
                        }
                        if let lang = movie.files.first?.languages.first {
                            Text(LanguageMap.name(for: lang))
                        }
                    }
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(.card)
    }

    private var posterImage: some View {
        Color.clear
            .aspectRatio(2/3, contentMode: .fit)
            .overlay {
                CoverImageView(
                    coverPath: movie.cover,
                    categoryId: movie.category.id,
                    movieName: movie.name
                )
            }
            .clipped()
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    if isNew {
                        badgeLabel("NEW", color: .green)
                    }
                    if let quality = qualityLabel {
                        badgeLabel(quality, color: .teal)
                    }
                }
                .padding(6)
            }
    }

    private func badgeLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color, in: .rect(cornerRadius: 4))
    }
}
