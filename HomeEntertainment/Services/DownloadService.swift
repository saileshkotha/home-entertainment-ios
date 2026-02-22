import Foundation

enum DownloadService {

    static func getDownloads() async throws -> [ParsedDownload] {
        let action = DownloadAction(action: "STATUS")
        let response: [String: DownloadStatus] = try await APIClient.shared.post(
            "/download",
            body: action,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        return response.map { ParsedDownload.parse(key: $0.key, status: $0.value) }
    }

    static func startDownload(
        fileName: String,
        url: String? = nil,
        urlOverride: String? = nil,
        movieId: Int? = nil,
        fileId: Int? = nil
    ) async throws {
        let action = DownloadAction(
            action: "START",
            fileName: fileName,
            url: url,
            urlOverride: urlOverride,
            movieId: movieId,
            fileId: fileId
        )
        try await APIClient.shared.postIgnoringResponse(
            "/download",
            body: action,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
    }

    static func cancelDownload(fileName: String) async throws {
        let action = DownloadAction(action: "STOP", fileName: fileName)
        try await APIClient.shared.postIgnoringResponse(
            "/download",
            body: action,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
    }
}
