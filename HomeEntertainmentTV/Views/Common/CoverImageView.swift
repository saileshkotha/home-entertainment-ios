import SwiftUI

struct CoverImageView: View {
    let coverPath: String?
    let categoryId: Int
    let movieName: String

    @State private var image: UIImage?
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ColorUtils.categoryGradient(for: categoryId)
                    .overlay {
                        Text(String(movieName.prefix(1)).uppercased())
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
            }
        }
        .task(id: coverPath) {
            guard !hasLoaded, let path = coverPath, !path.isEmpty else { return }
            hasLoaded = true

            if let cached = CoverImageCache.image(for: path) {
                image = cached
                return
            }

            do {
                let base64 = try await MovieService.getScreenshot(path: path)
                guard base64.count > 500 else { return }
                if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
                   let uiImage = UIImage(data: data) {
                    CoverImageCache.store(uiImage, for: path)
                    image = uiImage
                }
            } catch {}
        }
    }
}
