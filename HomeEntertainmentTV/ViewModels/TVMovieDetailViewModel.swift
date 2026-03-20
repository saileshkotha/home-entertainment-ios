import Foundation
import UIKit

@Observable
final class TVMovieDetailViewModel {
    var movie: Movie?
    var seasons: [Season] = []
    var episodesBySeasonId: [Int: [Episode]] = [:]
    var isLoading = false
    var coverImage: UIImage?
    var dominantColor: (red: CGFloat, green: CGFloat, blue: CGFloat)?
    var link: String?
    var isLoadingLink = false
    var isDownloading = false
    var error: String?
    var playURL: URL?
    var playbackFileId: Int?
    var playbackStartTime: Double = 0
    var movieResumeProgress: PlaybackProgress?

    private var loadTask: Task<Void, Never>?

    var canResumeMovie: Bool {
        PlaybackProgressStore.shouldOfferResume(movieResumeProgress)
    }

    var resumeLabelPercent: Int? {
        guard let progress = movieResumeProgress, canResumeMovie else { return nil }
        return Int((progress.percent * 100).rounded())
    }

    func load(movieId: Int) {
        loadTask?.cancel()
        reset()
        isLoading = true

        loadTask = Task { @MainActor in
            do {
                let m = try await MovieService.getMovie(id: movieId)
                guard !Task.isCancelled else { return }
                movie = m
                if !m.isTvSeries, let fileId = m.files.first?.id {
                    movieResumeProgress = PlaybackProgressStore.progress(forMovieFileId: fileId)
                }

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
                // Silently fail
            }
        }
    }

    func refreshMovieResumeProgress() {
        guard let movie, !movie.isTvSeries, let fileId = movie.files.first?.id else {
            movieResumeProgress = nil
            return
        }
        movieResumeProgress = PlaybackProgressStore.progress(forMovieFileId: fileId)
    }

    func play(movieId: Int, fileId: Int, startTime: Double = 0) {
        Task { @MainActor in
            isLoadingLink = true
            playURL = nil
            playbackFileId = nil
            playbackStartTime = 0
            if startTime <= 0 {
                PlaybackProgressStore.clearMovieProgress(fileId: fileId)
                movieResumeProgress = nil
            }
            do {
                let url = try await MovieService.getLink(movieId: movieId, fileId: fileId)
                link = url
                if let parsed = URL(string: url) {
                    playbackFileId = fileId
                    playbackStartTime = max(0, startTime)
                    playURL = parsed
                }
            } catch {
                self.error = "Failed to get link"
            }
            isLoadingLink = false
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
                    try await DownloadService.startDownload(
                        fileName: fileName, url: url, movieId: movieId, fileId: fileId
                    )
                    error = nil
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
        playURL = nil
        playbackFileId = nil
        playbackStartTime = 0
        movieResumeProgress = nil
        error = nil
        isLoading = false
        isLoadingLink = false
        isDownloading = false
    }

    private func loadCover(path: String) async throws {
        guard !path.isEmpty else { return }

        if let cached = CoverImageCache.image(for: path) {
            coverImage = cached
            dominantColor = Self.extractDominantColor(from: cached)
            return
        }

        let base64 = try await MovieService.getScreenshot(path: path)
        guard base64.count > 500, !Task.isCancelled else { return }
        if let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            CoverImageCache.store(image, for: path)
            coverImage = image
            dominantColor = Self.extractDominantColor(from: image)
        }
    }

    private static func extractDominantColor(from image: UIImage) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        guard let cgImage = image.cgImage else { return nil }
        let size = 20
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        guard let context = CGContext(
            data: &pixels, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: size * 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        let count = size * size
        for i in 0..<count {
            let offset = i * 4
            r += CGFloat(pixels[offset])
            g += CGFloat(pixels[offset + 1])
            b += CGFloat(pixels[offset + 2])
        }
        let n = CGFloat(count)
        return (red: r / n / 255, green: g / n / 255, blue: b / n / 255)
    }
}
