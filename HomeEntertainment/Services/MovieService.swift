import Foundation

private struct CachedValue<Value> {
    let value: Value
    let cachedAt: Date
    let expiresAt: Date?

    func isValid(at now: Date) -> Bool {
        expiresAt.map { $0 > now } ?? true
    }
}

private struct EpisodeKey: Hashable {
    let seriesId: Int
    let seasonId: Int
}

private actor MovieRepository {
    static let shared = MovieRepository()

    private let detailTTL: TimeInterval = 6 * 60 * 60
    private let screenshotTTL: TimeInterval = 10 * 60
    private let movieCacheLimit = 300
    private let seasonsCacheLimit = 300
    private let episodesCacheLimit = 600
    private let screenshotCacheLimit = 120

    private var movieCache: [Int: CachedValue<Movie>] = [:]
    private var seasonsCache: [Int: CachedValue<[Season]>] = [:]
    private var episodesCache: [EpisodeKey: CachedValue<[Episode]>] = [:]
    private var screenshotCache: [String: CachedValue<String>] = [:]

    private var inFlightMovie: [Int: Task<Movie, Error>] = [:]
    private var inFlightSeasons: [Int: Task<[Season], Error>] = [:]
    private var inFlightEpisodes: [EpisodeKey: Task<[Episode], Error>] = [:]
    private var inFlightScreenshot: [String: Task<String, Error>] = [:]

    func searchMovies(
        categoryId: Int,
        search: String?,
        sortBy: String,
        direction: String,
        limit: Int,
        offset: Int
    ) async throws -> [Movie] {
        let path = Self.searchPath(
            categoryId: categoryId,
            search: normalized(search),
            sortBy: sortBy,
            direction: direction,
            limit: limit,
            offset: offset
        )

        let response: APIResponse<[Movie]> = try await APIClient.shared.get(path)
        return response.data
    }

    func getMovie(id: Int) async throws -> Movie {
        let now = Date()
        if let cached = movieCache[id], cached.isValid(at: now) {
            return cached.value
        }

        if let task = inFlightMovie[id] {
            return try await task.value
        }

        let task = Task { () throws -> Movie in
            let response: APIResponse<Movie> = try await APIClient.shared.get("/movies/\(id)")
            return response.data
        }

        inFlightMovie[id] = task

        do {
            let movie = try await task.value
            // Do not cache details for items without cover. Some entries are backfilled later.
            if hasCover(movie: movie) {
                movieCache[id] = CachedValue(
                    value: movie,
                    cachedAt: Date(),
                    expiresAt: Date().addingTimeInterval(detailTTL)
                )
                pruneMovieCacheIfNeeded(now: Date())
            }
            inFlightMovie[id] = nil
            return movie
        } catch {
            inFlightMovie[id] = nil
            throw error
        }
    }

    func getSeasons(seriesId: Int) async throws -> [Season] {
        let now = Date()
        if let cached = seasonsCache[seriesId], cached.isValid(at: now) {
            return cached.value
        }

        if let task = inFlightSeasons[seriesId] {
            return try await task.value
        }

        let task = Task { () throws -> [Season] in
            let response: APIResponse<[Season]> = try await APIClient.shared.get("/movies/\(seriesId)/seasons")
            return response.data
        }

        inFlightSeasons[seriesId] = task

        do {
            let seasons = try await task.value
            seasonsCache[seriesId] = CachedValue(
                value: seasons,
                cachedAt: Date(),
                expiresAt: Date().addingTimeInterval(detailTTL)
            )
            pruneSeasonsCacheIfNeeded(now: Date())
            inFlightSeasons[seriesId] = nil
            return seasons
        } catch {
            inFlightSeasons[seriesId] = nil
            throw error
        }
    }

    func getEpisodes(seriesId: Int, seasonId: Int) async throws -> [Episode] {
        let key = EpisodeKey(seriesId: seriesId, seasonId: seasonId)
        let now = Date()

        if let cached = episodesCache[key], cached.isValid(at: now) {
            return cached.value
        }

        if let task = inFlightEpisodes[key] {
            return try await task.value
        }

        let task = Task { () throws -> [Episode] in
            let path = "/movies/\(seriesId)/seasons/\(seasonId)/episodes"
            let response: APIResponse<[Episode]> = try await APIClient.shared.get(path)
            return response.data
        }

        inFlightEpisodes[key] = task

        do {
            let episodes = try await task.value
            episodesCache[key] = CachedValue(
                value: episodes,
                cachedAt: Date(),
                expiresAt: Date().addingTimeInterval(detailTTL)
            )
            pruneEpisodesCacheIfNeeded(now: Date())
            inFlightEpisodes[key] = nil
            return episodes
        } catch {
            inFlightEpisodes[key] = nil
            throw error
        }
    }

    func getScreenshot(path: String) async throws -> String {
        let now = Date()
        if let cached = screenshotCache[path], cached.isValid(at: now) {
            return cached.value
        }

        if let task = inFlightScreenshot[path] {
            return try await task.value
        }

        let task = Task { () throws -> String in
            try await APIClient.shared.getText(path)
        }

        inFlightScreenshot[path] = task

        do {
            let base64 = try await task.value
            screenshotCache[path] = CachedValue(
                value: base64,
                cachedAt: Date(),
                expiresAt: Date().addingTimeInterval(screenshotTTL)
            )
            inFlightScreenshot[path] = nil
            pruneScreenshotCacheIfNeeded(now: Date())
            return base64
        } catch {
            inFlightScreenshot[path] = nil
            throw error
        }
    }

    private func pruneScreenshotCacheIfNeeded(now: Date) {
        screenshotCache = screenshotCache.filter { $0.value.isValid(at: now) }

        guard screenshotCache.count > screenshotCacheLimit else { return }

        let overflow = screenshotCache.count - screenshotCacheLimit
        let keysToRemove = screenshotCache
            .sorted { $0.value.cachedAt < $1.value.cachedAt }
            .prefix(overflow)
            .map(\.key)

        for key in keysToRemove {
            screenshotCache[key] = nil
        }
    }

    private func pruneMovieCacheIfNeeded(now: Date) {
        movieCache = movieCache.filter { $0.value.isValid(at: now) }
        trimIfNeeded(&movieCache, limit: movieCacheLimit)
    }

    private func pruneSeasonsCacheIfNeeded(now: Date) {
        seasonsCache = seasonsCache.filter { $0.value.isValid(at: now) }
        trimIfNeeded(&seasonsCache, limit: seasonsCacheLimit)
    }

    private func pruneEpisodesCacheIfNeeded(now: Date) {
        episodesCache = episodesCache.filter { $0.value.isValid(at: now) }
        trimIfNeeded(&episodesCache, limit: episodesCacheLimit)
    }

    private func trimIfNeeded<K, V>(_ cache: inout [K: CachedValue<V>], limit: Int) where K: Hashable {
        guard cache.count > limit else { return }

        let overflow = cache.count - limit
        let keysToRemove = cache
            .sorted { $0.value.cachedAt < $1.value.cachedAt }
            .prefix(overflow)
            .map(\.key)

        for key in keysToRemove {
            cache[key] = nil
        }
    }

    private static func searchPath(
        categoryId: Int,
        search: String?,
        sortBy: String,
        direction: String,
        limit: Int,
        offset: Int
    ) -> String {
        var components = URLComponents(string: "/movies")!
        components.queryItems = [
            URLQueryItem(name: "sortby", value: sortBy),
            URLQueryItem(name: "direction", value: direction),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        if let search, !search.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }

        if categoryId != 0 {
            components.queryItems?.append(URLQueryItem(name: "categoryId", value: String(categoryId)))
        }

        return components.string ?? "/movies"
    }

    private func normalized(_ search: String?) -> String? {
        guard let search else { return nil }
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func hasCover(movie: Movie) -> Bool {
        !movie.cover.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum MovieService {
    private static let repository = MovieRepository.shared

    static func searchMovies(
        categoryId: Int = 0,
        search: String? = nil,
        sortBy: String = "added",
        direction: String = "desc",
        limit: Int = AppConstants.pageSize,
        offset: Int = 0
    ) async throws -> [Movie] {
        try await repository.searchMovies(
            categoryId: categoryId,
            search: search,
            sortBy: sortBy,
            direction: direction,
            limit: limit,
            offset: offset
        )
    }

    static func getMovie(id: Int) async throws -> Movie {
        try await repository.getMovie(id: id)
    }

    static func getSeasons(seriesId: Int) async throws -> [Season] {
        try await repository.getSeasons(seriesId: seriesId)
    }

    static func getEpisodes(seriesId: Int, seasonId: Int) async throws -> [Episode] {
        try await repository.getEpisodes(seriesId: seriesId, seasonId: seasonId)
    }

    static func getLink(movieId: Int, fileId: Int) async throws -> String {
        let response: APIResponse<LinkData> = try await APIClient.shared.get(
            "/movies/\(movieId)/files/\(fileId)/link",
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        return response.data.url
    }

    static func getScreenshot(path: String) async throws -> String {
        try await repository.getScreenshot(path: path)
    }
}
