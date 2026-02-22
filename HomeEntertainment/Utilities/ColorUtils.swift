import SwiftUI

enum ColorUtils {
    static func categoryColor(for categoryId: Int) -> Color {
        let hue = Double((categoryId * 47 + 200) % 360) / 360.0
        return Color(hue: hue, saturation: 0.65, brightness: 0.45)
    }

    static func categoryGradient(for categoryId: Int) -> LinearGradient {
        let hue1 = Double((categoryId * 47 + 200) % 360) / 360.0
        let hue2 = Double((categoryId * 47 + 240) % 360) / 360.0
        return LinearGradient(
            colors: [
                Color(hue: hue1, saturation: 0.65, brightness: 0.45),
                Color(hue: hue2, saturation: 0.65, brightness: 0.35),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": .green
        case "downloading", "in_progress": .blue
        case "error", "failed": .red
        default: .gray
        }
    }
}

enum CoverImageCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 300
        cache.totalCostLimit = 150 * 1024 * 1024
        return cache
    }()

    static func image(for path: String) -> UIImage? {
        cache.object(forKey: path as NSString)
    }

    static func store(_ image: UIImage, for path: String) {
        let pixels = Int(image.size.width * image.size.height * image.scale * image.scale)
        let cost = max(pixels * 4, 1)
        cache.setObject(image, forKey: path as NSString, cost: cost)
    }
}
