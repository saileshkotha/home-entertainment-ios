import SwiftUI

struct SearchView: View {
    @State private var vm = SearchViewModel()
    @Binding var selectedMovie: Movie?
    @State private var didInitialLoad = false
    @State private var lastSelectedMovieId: Int?
    @State private var pendingRestoreMovieId: Int?
    @FocusState private var focusedMovieId: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 6)

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        searchField
                            .padding(.horizontal, 60)
                            .padding(.top, 20)
                            .padding(.bottom, 12)

                        filterBar
                            .padding(.horizontal, 60)
                            .padding(.bottom, 20)

                        if vm.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 400)
                        } else if vm.movies.isEmpty && !vm.searchText.isEmpty {
                            ContentUnavailableView("No results found", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity, minHeight: 400)
                        } else if vm.movies.isEmpty {
                            ContentUnavailableView {
                                Label("Browse or search", systemImage: "magnifyingglass")
                            } description: {
                                Text("Use the search bar or pick a category")
                            }
                            .frame(maxWidth: .infinity, minHeight: 400)
                        } else {
                            LazyVGrid(columns: columns, spacing: 50) {
                                ForEach(vm.movies) { movie in
                                    PosterCardView(movie: movie) {
                                        lastSelectedMovieId = movie.id
                                        focusedMovieId = movie.id
                                        selectedMovie = movie
                                    }
                                    .id(movie.id)
                                    .focused($focusedMovieId, equals: movie.id)
                                    .onAppear {
                                        if movie.id == vm.movies.last?.id {
                                            vm.loadMore()
                                        }
                                    }
                                }
                            }
                            .focusSection()
                            .padding(.horizontal, 60)
                            .padding(.vertical, 20)

                            if vm.isFetchingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 30)
                            }
                        }
                    }
                }
                .navigationDestination(item: $selectedMovie) { movie in
                    MovieDetailView(movieId: movie.id)
                }
                .onAppear {
                    guard !didInitialLoad else { return }
                    didInitialLoad = true
                    vm.search()
                }
                .onChange(of: selectedMovie) { _, movie in
                    if movie == nil {
                        restoreSelection(using: proxy)
                    }
                }
                .onChange(of: vm.movies.map(\.id)) { _, _ in
                    if pendingRestoreMovieId != nil {
                        restoreSelection(using: proxy)
                    }
                }
                .onChange(of: vm.selectedGroupId) { _, _ in vm.onGroupChanged() }
                .onChange(of: vm.selectedCategoryId) { _, _ in vm.search() }
                .onChange(of: vm.sortBy) { _, _ in vm.search() }
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search movies or series...", text: $vm.searchText)
                .onSubmit { vm.search() }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 20) {
            Menu {
                Picker("Category", selection: $vm.selectedGroupId) {
                    ForEach(vm.groups) { group in
                        Text(group.name).tag(group.id)
                    }
                }
            } label: {
                dropdownLabel(vm.currentGroup?.name ?? "Category")
            }

            Menu {
                Picker("Subcategory", selection: $vm.selectedCategoryId) {
                    ForEach(vm.subcategories, id: \.id) { sub in
                        Text(sub.label).tag(sub.id)
                    }
                }
            } label: {
                dropdownLabel(vm.subcategories.first(where: { $0.id == vm.selectedCategoryId })?.label ?? "All")
            }

            Button {
                vm.search()
            } label: {
                Label("Search", systemImage: "magnifyingglass")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)

            Spacer()

            Menu {
                Picker("Sort by", selection: $vm.sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                dropdownLabel(vm.sortBy.rawValue)
            }
        }
    }

    private func dropdownLabel(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .fontWeight(.semibold)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }

    private func restoreSelection(using proxy: ScrollViewProxy) {
        let targetId = pendingRestoreMovieId ?? lastSelectedMovieId
        guard let targetId else { return }

        guard vm.movies.contains(where: { $0.id == targetId }) else {
            pendingRestoreMovieId = targetId
            return
        }

        pendingRestoreMovieId = nil
        DispatchQueue.main.async {
            proxy.scrollTo(targetId, anchor: .center)
            focusedMovieId = targetId
        }
    }
}
