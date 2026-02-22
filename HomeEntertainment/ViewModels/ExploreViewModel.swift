import Foundation

struct CategoryGroup: Identifiable {
    let id: String
    let name: String
    let categories: [CategoryOption]
}

@Observable
final class ExploreViewModel {
    var movies: [Movie] = []
    var isLoading = false
    var isFetchingMore = false
    var hasMorePages = true
    var searchText = ""
    var selectedCategoryId: Int = AppConstants.defaultCategoryId
    var error: String?

    var categories: [CategoryOption] = []

    var selectedCategoryName: String {
        if selectedCategoryId == 0 { return "All Categories" }
        return categories.first { $0.id == selectedCategoryId }?.name ?? "All Categories"
    }

    var groupedCategories: [CategoryGroup] {
        var groups: [(key: String, items: [CategoryOption])] = []
        var seen: [String: Int] = [:]

        for cat in categories {
            let parts = cat.name.split(separator: "|", maxSplits: 1)
            let groupName = parts.first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? cat.name

            if let idx = seen[groupName] {
                groups[idx].items.append(cat)
            } else {
                seen[groupName] = groups.count
                groups.append((key: groupName, items: [cat]))
            }
        }

        return groups.map { CategoryGroup(id: $0.key, name: $0.key, categories: $0.items) }
    }

    private var currentOffset = 0
    private var searchTask: Task<Void, Never>?

    init() {
        loadCategories()
    }

    func loadCategories() {
        guard let url = Bundle.main.url(forResource: "movieCategories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CategoryOption].self, from: data) else {
            return
        }
        categories = decoded
    }

    func search() {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            currentOffset = 0
            hasMorePages = true
            isLoading = true
            error = nil

            do {
                let results = try await MovieService.searchMovies(
                    categoryId: selectedCategoryId,
                    search: searchText.isEmpty ? nil : searchText,
                    offset: 0
                )
                movies = results
                currentOffset = results.count
                hasMorePages = results.count >= AppConstants.pageSize
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            isLoading = false
        }
    }

    func loadMore() {
        guard !isFetchingMore, hasMorePages else { return }

        Task { @MainActor in
            isFetchingMore = true

            do {
                let results = try await MovieService.searchMovies(
                    categoryId: selectedCategoryId,
                    search: searchText.isEmpty ? nil : searchText,
                    offset: currentOffset
                )
                movies.append(contentsOf: results)
                currentOffset += results.count
                hasMorePages = results.count >= AppConstants.pageSize
            } catch {
                if !Task.isCancelled {
                    self.error = error.localizedDescription
                }
            }

            isFetchingMore = false
        }
    }
}
