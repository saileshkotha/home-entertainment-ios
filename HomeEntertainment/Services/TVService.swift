import Foundation

private struct GuideCacheKey: Hashable {
    let channelId: Int
    let from: Int
    let to: Int
}

private struct TVCachedValue<Value> {
    let value: Value
    let expiresAt: Date

    func isValid(at now: Date) -> Bool {
        expiresAt > now
    }
}

private actor TVRepository {
    static let shared = TVRepository()

    private let guideTTL: TimeInterval = 60

    private var guideCache: [GuideCacheKey: TVCachedValue<[TvProgram]>] = [:]
    private var inFlightGuide: [GuideCacheKey: Task<[TvProgram], Error>] = [:]

    func getCatchUpGuide(channelId: Int, from: Int, to: Int) async throws -> [TvProgram] {
        let key = GuideCacheKey(channelId: channelId, from: from, to: to)
        let now = Date()

        if let cached = guideCache[key], cached.isValid(at: now) {
            return cached.value
        }

        if let task = inFlightGuide[key] {
            return try await task.value
        }

        let task = Task { () throws -> [TvProgram] in
            let response: APIResponse<[TvProgram]> = try await APIClient.shared.get(
                "/tv-channels/\(channelId)/epg?from=\(from)&to=\(to)"
            )
            return response.data
        }

        inFlightGuide[key] = task

        do {
            let programs = try await task.value
            guideCache[key] = TVCachedValue(value: programs, expiresAt: Date().addingTimeInterval(guideTTL))
            inFlightGuide[key] = nil
            pruneExpiredGuides(now: Date())
            return programs
        } catch {
            inFlightGuide[key] = nil
            throw error
        }
    }

    private func pruneExpiredGuides(now: Date) {
        guideCache = guideCache.filter { $0.value.isValid(at: now) }
    }
}

enum TVService {
    private static let repository = TVRepository.shared

    static func getLiveTvLink(channelId: Int) async throws -> String {
        var lastError: Error?

        for attempt in 0...AppConstants.liveLinkRetryDelays.count {
            do {
                let response: APIResponse<LinkData> = try await APIClient.shared.get(
                    "/tv-channels/\(channelId)/link"
                )
                let url = response.data.url.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !url.isEmpty else {
                    throw APIError.emptyResponse
                }
                return url
            } catch {
                lastError = error
                if attempt < AppConstants.liveLinkRetryDelays.count {
                    try await Task.sleep(nanoseconds: AppConstants.liveLinkRetryDelays[attempt])
                }
            }
        }

        throw lastError ?? APIError.emptyResponse
    }

    static func getCatchUpGuide(channelId: Int, from: Int, to: Int) async throws -> [TvProgram] {
        try await repository.getCatchUpGuide(channelId: channelId, from: from, to: to)
    }

    static func getCatchUpLink(channelId: Int, programId: Int) async throws -> String {
        let response: APIResponse<LinkData> = try await APIClient.shared.get(
            "/tv-channels/\(channelId)/epg/\(programId)/link"
        )
        return response.data.url
    }
}
