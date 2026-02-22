import Foundation
import SwiftUI

@Observable
final class MovieDetailViewModel {
    var movie: Movie?
    var seasons: [Season] = []
    var episodesBySeasonId: [Int: [Episode]] = [:]
    var isLoading = false
    var coverImage: UIImage?
    var link: String?
    var isLoadingLink = false
    var isDownloading = false
    var error: String?

    private var loadTask: Task<Void, Never>?

    func load(movieId: Int) {
        loadTask?.cancel()
        reset()
        isLoading = true

        loadTask = Task { @MainActor in
            do {
                let m = try await MovieService.getMovie(id: movieId)
                guard !Task.isCancelled else { return }
                movie = m

                async let coverTask: Void = loadCover(path: m.cover)
                async let seasonsTask: Void = {
                    if m.isTvSeries {
                        let s = try await MovieService.getSeasons(seriesId: m.id)
                        if !Task.isCancelled { self.seasons = s }
                    }
                }()

                _ = try await (coverTask, seasonsTask)
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            isLoading = false
        }
    }

    func loadEpisodes(seriesId: Int, seasonId: Int) {
        guard episodesBySeasonId[seasonId] == nil else { return }

        Task { @MainActor in
            do {
                let eps = try await MovieService.getEpisodes(seriesId: seriesId, seasonId: seasonId)
                episodesBySeasonId[seasonId] = eps
            } catch {
                // Silently fail for episodes
            }
        }
    }

    func getLink(movieId: Int, fileId: Int) async -> String? {
        isLoadingLink = true
        defer { isLoadingLink = false }

        do {
            let url = try await MovieService.getLink(movieId: movieId, fileId: fileId)
            link = url
            return url
        } catch {
            self.error = "Failed to get link"
            return nil
        }
    }

    func downloadToPlex(movieId: Int, fileId: Int, fileName: String) {
        Task { @MainActor in
            isDownloading = true
            do {
                var url = link
                if url == nil {
                    url = try await MovieService.getLink(movieId: movieId, fileId: fileId)
                    link = url
                }
                if let url {
                    try await DownloadService.startDownload(fileName: fileName, url: url, movieId: movieId, fileId: fileId)
                }
            } catch {
                self.error = "Download failed"
            }
            isDownloading = false
        }
    }

    func reset() {
        movie = nil
        seasons = []
        episodesBySeasonId = [:]
        coverImage = nil
        link = nil
        error = nil
        isLoading = false
        isLoadingLink = false
        isDownloading = false
    }

    private func loadCover(path: String) async throws {
        guard !path.isEmpty else { return }

        if let cached = CoverImageCache.image(for: path) {
            coverImage = cached
            return
        }

        let base64 = try await MovieService.getScreenshot(path: path)
        guard base64.count > 500, !Task.isCancelled else { return }
        if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            CoverImageCache.store(image, for: path)
            coverImage = image
        }
    }
}
