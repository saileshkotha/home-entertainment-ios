import SwiftUI

struct RatingBarView: View {
    let label: String
    let rating: Double
    let maxRating: Double

    private var progress: Double { min(max(rating / maxRating, 0), 1) }

    private var ratingColor: Color {
        if rating >= 7 { return .green }
        if rating >= 5 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(String(format: "%.1f", rating))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(ratingColor)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(ratingColor)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
            .frame(width: 120)
        }
    }
}
