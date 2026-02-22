import SwiftUI

struct DownloadsView: View {
    @Environment(DownloadsViewModel.self) private var vm
    @State private var showAddSheet = false

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Picker("Filter", selection: $vm.filter) {
                        ForEach(DownloadFilter.allCases, id: \.self) { filter in
                            Text(filterLabel(filter)).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)

                    if vm.filter == .completed {
                        HStack {
                            Spacer()
                            Button("Clear All", role: .destructive) {
                                vm.clearAllCompleted()
                            }
                            .font(.caption)
                            .disabled(vm.filtered.filter(\.isCompleted).isEmpty)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)

                if let error = vm.error {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.tint(.orange), in: .rect(cornerRadius: 8))
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                if vm.filtered.isEmpty && vm.error == nil {
                    ContentUnavailableView {
                        Label("No downloads", systemImage: "arrow.down.circle")
                            .foregroundStyle(Theme.downloads)
                    } description: {
                        Text(vm.filter != .all ? "Try a different filter" : "Tap + to start one")
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if vm.filter == .all {
                                if !vm.activeDownloads.isEmpty {
                                    sectionHeader("Active", count: vm.activeDownloads.count, color: Theme.accent)
                                    ForEach(vm.activeDownloads) { download in
                                        DownloadRowView(download: download) {
                                            vm.cancelDownload(key: download.key)
                                        }
                                    }
                                }

                                if !vm.completedDownloads.isEmpty {
                                    sectionHeader("Completed", count: vm.completedDownloads.count, color: .green)
                                        .padding(.top, vm.activeDownloads.isEmpty ? 0 : 8)
                                    ForEach(vm.completedDownloads) { download in
                                        DownloadRowView(download: download, onDelete: {
                                            vm.cancelDownload(key: download.key)
                                        }, compact: true)
                                    }
                                }
                            } else {
                                ForEach(vm.filtered) { download in
                                    DownloadRowView(
                                        download: download,
                                        onDelete: { vm.cancelDownload(key: download.key) },
                                        compact: download.isCompleted
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddDownloadSheet { url, fileName in
                    vm.startDownload(fileName: fileName, urlOverride: url)
                }
            }
            .onAppear { vm.startPolling(interval: 1) }
            .onDisappear { vm.stopPolling() }
        }
    }

    private func sectionHeader(_ title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .textCase(.uppercase)
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12), in: Capsule())
                .foregroundStyle(color)
            Spacer()
        }
    }

    private func filterLabel(_ filter: DownloadFilter) -> String {
        let count: Int
        switch filter {
        case .all: count = vm.downloads.count
        case .active: count = vm.downloads.filter(\.isActive).count
        case .completed: count = vm.downloads.filter(\.isCompleted).count
        case .failed: count = vm.downloads.filter(\.isFailed).count
        }
        return "\(filter.rawValue) (\(count))"
    }
}
