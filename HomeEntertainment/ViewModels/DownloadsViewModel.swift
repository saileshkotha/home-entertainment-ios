import Foundation

enum DownloadFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case failed = "Failed"
}

@Observable
final class DownloadsViewModel {
    var downloads: [ParsedDownload] = []
    var filter: DownloadFilter = .all
    var isLoading = false
    var error: String?

    var activeCount: Int {
        downloads.filter(\.isActive).count
    }

    var filtered: [ParsedDownload] {
        switch filter {
        case .all: downloads
        case .active: downloads.filter(\.isActive)
        case .completed: downloads.filter(\.isCompleted)
        case .failed: downloads.filter(\.isFailed)
        }
    }

    var activeDownloads: [ParsedDownload] {
        filtered.filter(\.isActive)
    }

    var completedDownloads: [ParsedDownload] {
        filtered.filter { !$0.isActive }
    }

    private var pollTask: Task<Void, Never>?
    private var currentPollInterval: TimeInterval?

    func startPolling(interval: TimeInterval = AppConstants.downloadPollInterval) {
        let normalizedInterval = max(1, interval)

        if pollTask != nil {
            if currentPollInterval == normalizedInterval { return }
            stopPolling()
        }

        currentPollInterval = normalizedInterval
        pollTask = Task { @MainActor in
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(normalizedInterval))
            }
            pollTask = nil
            currentPollInterval = nil
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
        currentPollInterval = nil
    }

    func refresh() async {
        do {
            let results = try await DownloadService.getDownloads()
            if !Task.isCancelled {
                downloads = results
                error = nil
            }
        } catch {
            if !Task.isCancelled {
                print("[Downloads] refresh failed: \(error)")
                self.error = error.localizedDescription
            }
        }
    }

    func cancelDownload(key: String) {
        Task { @MainActor in
            do {
                try await DownloadService.cancelDownload(fileName: key)
                await refresh()
            } catch {
                self.error = "Failed to cancel download"
            }
        }
    }

    func clearAllCompleted() {
        Task { @MainActor in
            let completed = downloads.filter(\.isCompleted)
            for d in completed {
                try? await DownloadService.cancelDownload(fileName: d.key)
            }
            await refresh()
        }
    }

    func startDownload(fileName: String, urlOverride: String) {
        Task { @MainActor in
            do {
                try await DownloadService.startDownload(fileName: fileName, urlOverride: urlOverride)
                await refresh()
            } catch {
                self.error = "Failed to start download"
            }
        }
    }
}
