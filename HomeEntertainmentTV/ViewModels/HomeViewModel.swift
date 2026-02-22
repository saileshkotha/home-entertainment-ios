import Foundation

struct HomeShelf: Identifiable {
    let id: Int
    let name: String
    var movies: [Movie]
}

@Observable
final class HomeViewModel {
    var heroMovies: [Movie] = []
    var shelves: [HomeShelf] = []
    var favoriteChannels: [TvChannel] = []
    var allChannels: [TvChannel] = []
    var isLoading = false
    var error: String?

    private static let shelfDefinitions: [(id: Int, name: String)] = [
        (14, "Telugu Movies"),
        (5, "Hindi Movies"),
        (2, "English Movies"),
        (9, "Tamil Movies"),
    ]

    private var hasLoaded = false

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true

        loadChannels()
        loadFavorites()

        Task { @MainActor in
            async let heroTask = loadHero()
            async let shelvesTask = loadShelves()
            _ = await (heroTask, shelvesTask)
            isLoading = false
        }
    }

    private func loadHero() async {
        do {
            let movies = try await MovieService.searchMovies(
                sortBy: "added", direction: "desc", limit: 5, offset: 0
            )
            heroMovies = movies
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadShelves() async {
        var loaded: [HomeShelf] = []
        for def in Self.shelfDefinitions {
            do {
                let movies = try await MovieService.searchMovies(
                    categoryId: def.id, sortBy: "added", direction: "desc",
                    limit: 12, offset: 0
                )
                loaded.append(HomeShelf(id: def.id, name: def.name, movies: movies))
            } catch {
                // Skip shelves that fail to load
            }
        }
        shelves = loaded
    }

    private func loadChannels() {
        guard let url = Bundle.main.url(forResource: "channels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([TvChannel].self, from: data) else {
            return
        }
        allChannels = decoded
        loadFavorites()
    }

    func loadFavorites() {
        let ids = UserDefaults.standard.array(forKey: "favoriteChannelIds") as? [Int] ?? []
        favoriteChannels = allChannels.filter { ids.contains($0.id) }
    }
}
