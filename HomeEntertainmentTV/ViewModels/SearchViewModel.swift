import Foundation

struct BrowseCategoryGroup: Identifiable, Hashable {
    let id: String
    let name: String
    var subcategories: [(id: Int, label: String)]

    static func == (lhs: BrowseCategoryGroup, rhs: BrowseCategoryGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum SortOption: String, CaseIterable {
    case added = "Recently Added"
    case ratingImdb = "Top Rated (IMDb)"
    case year = "Year"

    var apiSortBy: String {
        switch self {
        case .added: "added"
        case .ratingImdb: "rating_imdb"
        case .year: "year"
        }
    }
}

@Observable
final class SearchViewModel {
    var groups: [BrowseCategoryGroup] = []
    var selectedGroupId: String = ""
    var selectedCategoryId: Int = 0
    var sortBy: SortOption = .added
    var searchText = ""
    var movies: [Movie] = []
    var isLoading = false
    var isFetchingMore = false
    var hasMore = true
    var error: String?

    private var currentOffset = 0
    private var searchTask: Task<Void, Never>?

    var currentGroup: BrowseCategoryGroup? {
        groups.first { $0.id == selectedGroupId }
    }

    var subcategories: [(id: Int, label: String)] {
        currentGroup?.subcategories ?? []
    }

    init() {
        loadCategories()
    }

    func onGroupChanged() {
        if let first = currentGroup?.subcategories.first {
            selectedCategoryId = first.id
        }
        search()
    }

    func search() {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            guard selectedCategoryId != 0 else { return }
            currentOffset = 0
            hasMore = true
            isLoading = true
            movies = []
            error = nil

            do {
                let results = try await MovieService.searchMovies(
                    categoryId: selectedCategoryId,
                    search: searchText.isEmpty ? nil : searchText,
                    sortBy: sortBy.apiSortBy,
                    direction: "desc",
                    offset: 0
                )
                guard !Task.isCancelled else { return }
                movies = results
                currentOffset = results.count
                hasMore = results.count >= AppConstants.pageSize
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            isLoading = false
        }
    }

    func loadMore() {
        guard !isFetchingMore, hasMore else { return }

        Task { @MainActor in
            isFetchingMore = true

            do {
                let results = try await MovieService.searchMovies(
                    categoryId: selectedCategoryId,
                    search: searchText.isEmpty ? nil : searchText,
                    sortBy: sortBy.apiSortBy,
                    direction: "desc",
                    offset: currentOffset
                )
                movies.append(contentsOf: results)
                currentOffset += results.count
                hasMore = results.count >= AppConstants.pageSize
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            isFetchingMore = false
        }
    }

    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "movieCategories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CategoryOption].self, from: data) else {
            return
        }

        var groupOrder: [String] = []
        var groupMap: [String: [(id: Int, label: String)]] = [:]

        for cat in decoded {
            let parts = cat.name.split(separator: "|", maxSplits: 1)
            let groupName = parts.first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? cat.name
            let subLabel = parts.count > 1
                ? String(parts[1]).trimmingCharacters(in: .whitespaces)
                : groupName

            if groupMap[groupName] == nil {
                groupOrder.append(groupName)
            }
            groupMap[groupName, default: []].append((id: cat.id, label: subLabel))
        }

        groups = groupOrder.compactMap { name in
            guard let subs = groupMap[name], !subs.isEmpty else { return nil }
            return BrowseCategoryGroup(id: name, name: name, subcategories: subs)
        }

        if let firstGroup = groups.first {
            selectedGroupId = firstGroup.id
            if let firstSub = firstGroup.subcategories.first {
                selectedCategoryId = firstSub.id
            }
        }
    }
}
