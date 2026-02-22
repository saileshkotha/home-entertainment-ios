import Foundation

struct DownloadStatus: Decodable {
    let status: String?
    let error: String?
    let percentCompleted: Double?
}

struct DownloadAction: Encodable {
    let action: String
    var fileName: String?
    var url: String?
    var urlOverride: String?
    var movieId: Int?
    var fileId: Int?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encodeIfPresent(fileName, forKey: .fileName)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(urlOverride, forKey: .urlOverride)
        try container.encodeIfPresent(movieId, forKey: .movieId)
        try container.encodeIfPresent(fileId, forKey: .fileId)
    }

    private enum CodingKeys: String, CodingKey {
        case action, fileName, url, urlOverride, movieId, fileId
    }
}

enum DownloadMediaType: String {
    case movie, tv, unknown
}

struct ParsedDownload: Identifiable {
    let key: String
    let status: String
    let error: String
    let percentCompleted: Double
    let displayName: String
    let type: DownloadMediaType
    var year: String?
    var season: String?
    var episode: String?
    var language: String?

    var id: String { key }

    var isActive: Bool {
        let s = status.lowercased()
        return s != "completed" && s != "error" && s != "failed"
    }

    var isCompleted: Bool {
        status.lowercased() == "completed"
    }

    var isFailed: Bool {
        let s = status.lowercased()
        return s == "error" || s == "failed"
    }

    static func parse(key: String, status: DownloadStatus) -> ParsedDownload {
        let normalizedStatus = normalizeStatus(status.status ?? "unknown")
        let info = parseFileName(key)

        return ParsedDownload(
            key: key,
            status: normalizedStatus,
            error: status.error ?? "",
            percentCompleted: status.percentCompleted ?? 0,
            displayName: info.displayName,
            type: info.type,
            year: info.year,
            season: info.season,
            episode: info.episode,
            language: info.language
        )
    }
}

private func normalizeStatus(_ status: String) -> String {
    let normalized = status.trimmingCharacters(in: .whitespaces).lowercased()
    return normalized == "finished" ? "completed" : normalized
}

private struct FileNameInfo {
    var displayName: String
    var type: DownloadMediaType
    var year: String?
    var season: String?
    var episode: String?
    var language: String?
}

private func parseFileName(_ key: String) -> FileNameInfo {
    // Movie: Videos/Movie Name (2026).mp4
    let moviePattern = #/^Videos/(.+?)\s*\((\d{4})\)\.mp4$/#
    if let match = try? moviePattern.firstMatch(in: key) {
        return FileNameInfo(
            displayName: String(match.1).trimmingCharacters(in: .whitespaces),
            type: .movie,
            year: String(match.2)
        )
    }

    // TV: TVShows/Series Name - s01e05 - Telugu Episode Name.mp4
    let tvPattern = #/^TVShows/(.+?)\s*-\s*s(\d+)e(\d+)\s*(?:-\s*(\w+)\s+)?(.*)\.mp4$/#
    if let match = try? tvPattern.firstMatch(in: key) {
        return FileNameInfo(
            displayName: String(match.1).trimmingCharacters(in: .whitespaces),
            type: .tv,
            season: String(match.2),
            episode: String(match.3),
            language: match.4.map(String.init)
        )
    }

    // Fallback
    var fallbackName = key
    if fallbackName.hasPrefix("Videos/") { fallbackName = String(fallbackName.dropFirst(7)) }
    if fallbackName.hasPrefix("TVShows/") { fallbackName = String(fallbackName.dropFirst(8)) }
    if fallbackName.hasSuffix(".mp4") { fallbackName = String(fallbackName.dropLast(4)) }

    let inferredType: DownloadMediaType =
        key.hasPrefix("TVShows/") ? .tv :
        key.hasPrefix("Videos/") ? .movie : .unknown

    return FileNameInfo(
        displayName: fallbackName.isEmpty ? key : fallbackName,
        type: inferredType
    )
}
