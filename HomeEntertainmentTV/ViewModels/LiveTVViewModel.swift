import Foundation

@Observable
final class LiveTVViewModel {
    var allChannels: [TvChannel] = []
    var filteredChannels: [TvChannel] = []
    var channelCategories: [Category] = []
    var selectedCategoryId: String = "all"
    var searchText = ""
    var selectedChannel: TvChannel?
    var catchupDate = Date()

    var guide: [TvProgram] = []
    var isLoadingGuide = false
    var isLoadingLink = false
    var isDownloading = false

    var activeLink: ActiveLink?
    var error: String?

    struct ActiveLink: Equatable {
        let key: String
        let url: String
        let label: String
    }

    private var linkRequestId = 0
    private var guideTask: Task<Void, Never>?

    var favoriteChannelIds: Set<Int> {
        get {
            let ids = UserDefaults.standard.array(forKey: "favoriteChannelIds") as? [Int] ?? []
            return Set(ids)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "favoriteChannelIds")
        }
    }

    var favoriteChannels: [TvChannel] {
        allChannels.filter { favoriteChannelIds.contains($0.id) }
    }

    init() {
        loadChannels()
    }

    func loadChannels() {
        guard let url = Bundle.main.url(forResource: "channels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TvChannel].self, from: data) else {
            return
        }

        allChannels = decoded

        let categoryMap = Dictionary(grouping: decoded, by: { $0.genre.id })
        channelCategories = categoryMap.values
            .compactMap(\.first?.genre)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if let telugu = channelCategories.first(where: { $0.name.uppercased() == "TELUGU" }) {
            selectedCategoryId = String(telugu.id)
        }

        filterChannels()
    }

    func filterChannels() {
        filteredChannels = allChannels.filter { channel in
            let byCategory = selectedCategoryId == "all" || String(channel.genre.id) == selectedCategoryId
            let bySearch = searchText.isEmpty ||
                channel.name.localizedCaseInsensitiveContains(searchText) ||
                channel.genre.name.localizedCaseInsensitiveContains(searchText)
            return byCategory && bySearch
        }

        if let selected = selectedChannel,
           !filteredChannels.contains(where: { $0.id == selected.id }) {
            selectedChannel = filteredChannels.first
        } else if selectedChannel == nil {
            selectedChannel = filteredChannels.first
        }
    }

    func selectChannel(_ channel: TvChannel) {
        selectedChannel = channel
        activeLink = nil
    }

    func toggleFavorite(_ channel: TvChannel) {
        var ids = favoriteChannelIds
        if ids.contains(channel.id) {
            ids.remove(channel.id)
        } else {
            ids.insert(channel.id)
        }
        favoriteChannelIds = ids
    }

    func isFavorite(_ channel: TvChannel) -> Bool {
        favoriteChannelIds.contains(channel.id)
    }

    // MARK: - Guide

    func loadGuide() {
        guard let channel = selectedChannel else { return }
        guideTask?.cancel()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: catchupDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        let from = Int(startOfDay.timeIntervalSince1970)
        let to = Int(endOfDay.timeIntervalSince1970)

        isLoadingGuide = true
        guideTask = Task { @MainActor in
            do {
                let programs = try await TVService.getCatchUpGuide(channelId: channel.id, from: from, to: to)
                guard !Task.isCancelled else { return }
                guide = programs.sorted { $0.start > $1.start }
            } catch {
                if !Task.isCancelled {
                    guide = []
                }
            }
            isLoadingGuide = false
        }
    }

    // MARK: - Links

    func fetchLiveLink() {
        guard let channel = selectedChannel else { return }
        let rowKey = "live-\(channel.id)"
        linkRequestId += 1
        let requestId = linkRequestId

        invalidateExistingLink(newKey: rowKey)
        isLoadingLink = true

        Task { @MainActor in
            do {
                let url = try await TVService.getLiveTvLink(channelId: channel.id)
                guard requestId == linkRequestId else { return }
                activeLink = ActiveLink(key: rowKey, url: url, label: channel.name)
            } catch {
                guard requestId == linkRequestId else { return }
                self.error = "Failed to get live link"
            }
            isLoadingLink = false
        }
    }

    func fetchCatchupLink(program: TvProgram) {
        guard let channel = selectedChannel else { return }
        let rowKey = "catchup-\(channel.id)-\(program.id)"
        linkRequestId += 1
        let requestId = linkRequestId

        invalidateExistingLink(newKey: rowKey)
        isLoadingLink = true

        Task { @MainActor in
            do {
                let url = try await TVService.getCatchUpLink(channelId: channel.id, programId: program.id)
                guard requestId == linkRequestId else { return }
                activeLink = ActiveLink(key: rowKey, url: url, label: "\(channel.name) - \(program.name)")
            } catch {
                guard requestId == linkRequestId else { return }
                self.error = "Failed to get catch up link"
            }
            isLoadingLink = false
        }
    }

    func downloadToPlex(rowKey: String, fileName: String) {
        guard let link = activeLink, link.key == rowKey else {
            error = "Generate link first"
            return
        }

        isDownloading = true
        Task { @MainActor in
            do {
                try await DownloadService.startDownload(fileName: fileName, urlOverride: link.url)
            } catch {
                self.error = "Failed to start download"
            }
            isDownloading = false
        }
    }

    private func invalidateExistingLink(newKey: String) {
        if let existing = activeLink, existing.key != newKey {
            activeLink = nil
        }
    }
}
