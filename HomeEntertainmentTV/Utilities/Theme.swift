import SwiftUI

enum Theme {
    static let accent = Color.indigo
    static let explore = Color.indigo
    static let tv = Color.teal
    static let downloads = Color.orange

    static let cardBackground = Color.white.opacity(0.08)
    static let sectionHeader = Color.white.opacity(0.6)

    static let posterWidth: CGFloat = 220
    static let posterHeight: CGFloat = 330
}

struct PlaybackProgress: Codable, Equatable {
    let fileId: Int
    let positionSeconds: Double
    let durationSeconds: Double
    let percent: Double
    let updatedAt: Date
}

enum PlaybackProgressStore {
    private static let keyPrefix = "playbackProgress.movie."
    private static let minResumePercent = 0.05
    private static let completionPercent = 0.95
    private static let minSavedPosition: Double = 30

    static func progress(forMovieFileId fileId: Int) -> PlaybackProgress? {
        let key = storageKey(for: fileId)
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlaybackProgress.self, from: data)
    }

    static func saveMovieProgress(fileId: Int, positionSeconds: Double, durationSeconds: Double) {
        guard durationSeconds.isFinite, durationSeconds > 0 else { return }

        let percent = min(max(positionSeconds / durationSeconds, 0), 1)

        if percent >= completionPercent {
            clearMovieProgress(fileId: fileId)
            return
        }

        guard positionSeconds >= minSavedPosition else { return }

        let progress = PlaybackProgress(
            fileId: fileId,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            percent: percent,
            updatedAt: Date()
        )

        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(for: fileId))
    }

    static func clearMovieProgress(fileId: Int) {
        UserDefaults.standard.removeObject(forKey: storageKey(for: fileId))
    }

    static func shouldOfferResume(_ progress: PlaybackProgress?) -> Bool {
        guard let progress else { return false }
        return progress.percent >= minResumePercent && progress.percent < completionPercent
    }

    private static func storageKey(for fileId: Int) -> String {
        "\(keyPrefix)\(fileId)"
    }
}
