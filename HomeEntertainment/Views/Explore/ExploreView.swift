import SwiftUI

struct ExploreView: View {
    @State private var vm = ExploreViewModel()
    @State private var selectedMovie: Movie?
    @State private var showCategoryPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        showCategoryPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(vm.selectedCategoryName)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent, in: .capsule)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)

                ScrollView {
                    MediaGridView(
                        movies: vm.movies,
                        isLoading: vm.isLoading,
                        isFetchingMore: vm.isFetchingMore,
                        hasMore: vm.hasMorePages,
                        onLoadMore: { vm.loadMore() },
                        onSelect: { selectedMovie = $0 }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, prompt: "Search movies or series...")
            .onSubmit(of: .search) { vm.search() }
            .onChange(of: vm.selectedCategoryId) { _, _ in vm.search() }
            .onAppear {
                if vm.movies.isEmpty { vm.search() }
            }
            .sheet(item: $selectedMovie) { movie in
                MediaDetailView(movieId: movie.id)
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(
                    groups: vm.groupedCategories,
                    selectedId: vm.selectedCategoryId
                ) { id in
                    vm.selectedCategoryId = id
                    showCategoryPicker = false
                }
            }
            .refreshable { vm.search() }
        }
    }
}

// MARK: - Category Picker Sheet

private struct CategoryPickerSheet: View {
    let groups: [CategoryGroup]
    let selectedId: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredGroups: [CategoryGroup] {
        if searchText.isEmpty { return groups }
        let query = searchText.lowercased()
        return groups.compactMap { group in
            let matched = group.categories.filter {
                $0.name.lowercased().contains(query) ||
                group.name.lowercased().contains(query)
            }
            guard !matched.isEmpty else { return nil }
            return CategoryGroup(id: group.id, name: group.name, categories: matched)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(0)
                } label: {
                    HStack {
                        Text("All Categories")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedId == 0 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }

                ForEach(filteredGroups) { group in
                    Section(group.name) {
                        ForEach(group.categories) { category in
                            Button {
                                onSelect(category.id)
                            } label: {
                                HStack {
                                    Text(subcategoryLabel(category.name, group: group.name))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if category.id == selectedId {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accent)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search categories...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func subcategoryLabel(_ fullName: String, group: String) -> String {
        let parts = fullName.split(separator: "|", maxSplits: 1)
        if parts.count == 2 {
            return parts[1].trimmingCharacters(in: .whitespaces)
        }
        return fullName
    }
}
