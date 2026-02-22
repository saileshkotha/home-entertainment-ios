import SwiftUI

struct DownloadsView: View {
    @Environment(DownloadsViewModel.self) private var vm
    enum DownloadFocus: Hashable { case filterPicker, clearCompleted }
    @FocusState private var focusedControl: DownloadFocus?

    private var activeDownloads: [ParsedDownload] { vm.downloads.filter(\.isActive) }
    private var completedDownloads: [ParsedDownload] { vm.downloads.filter(\.isCompleted) }
    private var failedDownloads: [ParsedDownload] { vm.downloads.filter(\.isFailed) }

    private var queueProgress: Double {
        guard !activeDownloads.isEmpty else {
            return completedDownloads.isEmpty ? 0 : 100
        }
        let total = activeDownloads.reduce(0) { $0 + clampedPercent($1.percentCompleted) }
        return total / Double(activeDownloads.count)
    }

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            ZStack {
                backdrop

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        commandDeck(filter: $vm.filter)

                        if let error = vm.error {
                            errorBanner(error)
                        }

                        if vm.filtered.isEmpty && vm.error == nil {
                            emptyState
                                .frame(maxWidth: .infinity, minHeight: 420)
                        } else {
                            if vm.filter == .all {
                                if !activeDownloads.isEmpty {
                                    sectionHeader("In Transit", count: activeDownloads.count, tint: Theme.accent)
                                    ForEach(activeDownloads) { download in
                                        activeCard(download)
                                    }
                                }

                                if !completedDownloads.isEmpty {
                                    sectionHeader("Archive", count: completedDownloads.count, tint: .green)
                                        .padding(.top, activeDownloads.isEmpty ? 0 : 8)
                                    ForEach(completedDownloads) { download in
                                        historyCard(download)
                                    }
                                }

                                if !failedDownloads.isEmpty {
                                    sectionHeader("Needs Attention", count: failedDownloads.count, tint: .orange)
                                        .padding(.top, 8)
                                    ForEach(failedDownloads) { download in
                                        historyCard(download)
                                    }
                                }
                            } else {
                                sectionHeader(vm.filter.rawValue, count: vm.filtered.count, tint: sectionTint(for: vm.filter))
                                ForEach(vm.filtered) { download in
                                    if download.isActive {
                                        activeCard(download)
                                    } else {
                                        historyCard(download)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 56)
                    .padding(.top, 20)
                    .padding(.bottom, 44)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Downloads")
            .onAppear { vm.startPolling(interval: 1) }
            .onDisappear { vm.stopPolling() }
        }
    }

    // MARK: - Shell

    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.03, green: 0.03, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Theme.downloads.opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 460
            )

            RadialGradient(
                colors: [Theme.accent.opacity(0.2), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private func commandDeck(filter: Binding<DownloadFilter>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Queue Control")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                    Text("Monitor active transfers and clean up completed media")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 20)

                if filter.wrappedValue == .completed {
                    Button {
                        vm.clearAllCompleted()
                    } label: {
                        Label("Clear Completed", systemImage: "trash")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(minWidth: 180)
                    }
                    .buttonStyle(.bordered)
                    .focused($focusedControl, equals: .clearCompleted)
                    .disabled(vm.filtered.filter(\.isCompleted).isEmpty)
                    .onMoveCommand { direction in
                        if direction == .down {
                            focusedControl = .filterPicker
                        }
                    }
                }
            }

            Picker("Filter", selection: filter) {
                ForEach(DownloadFilter.allCases, id: \.self) { filter in
                    Text(filterLabel(filter)).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .focused($focusedControl, equals: .filterPicker)
            .onMoveCommand { direction in
                if direction == .up, filter.wrappedValue == .completed {
                    focusedControl = .clearCompleted
                }
            }

            HStack(spacing: 10) {
                metricPill(label: "Active", value: activeDownloads.count, tint: Theme.accent)
                metricPill(label: "Completed", value: completedDownloads.count, tint: .green)
                metricPill(label: "Failed", value: failedDownloads.count, tint: .orange)
                Spacer(minLength: 14)
                Text("Queue Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(queueProgress))%")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
            }

            ProgressView(value: queueProgress, total: 100)
                .tint(Theme.downloads)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)
        }
        .onChange(of: filter.wrappedValue) { _, newValue in
            if newValue != .completed, focusedControl == .clearCompleted {
                focusedControl = .filterPicker
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.45), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.downloads, Theme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Queue is Quiet")
                .font(.title2)
                .fontWeight(.bold)

            Text(vm.filter != .all ? "Try a broader filter." : "Start downloads from Explore or Search.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Cards

    private func activeCard(_ download: ParsedDownload) -> some View {
        let progress = clampedPercent(download.percentCompleted)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 10) {
                        Text(download.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(1)

                        metadataPills(download)
                    }

                    HStack(spacing: 10) {
                        mediaTypeBadge(download.type)
                        statusBadge(download.status, tint: statusColor(download))
                    }
                }

                Spacer(minLength: 12)

                Text("\(Int(progress))%")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            ProgressView(value: progress, total: 100)
                .tint(statusColor(download))
                .scaleEffect(x: 1, y: 1.35, anchor: .center)

            HStack {
                if !download.error.isEmpty && download.error != "None" {
                    Text(download.error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    vm.cancelDownload(key: download.key)
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 110)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(activeCardBackground(download), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func historyCard(_ download: ParsedDownload) -> some View {
        HStack(spacing: 14) {
            Image(systemName: iconName(download))
                .font(.title3)
                .foregroundStyle(iconColor(download))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(download.displayName)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    metadataPills(download)
                }

                HStack(spacing: 8) {
                    mediaTypeBadge(download.type)
                    statusBadge(download.status, tint: statusColor(download))
                }
            }

            Spacer()

            if download.isFailed {
                Text(download.error.isEmpty || download.error == "None" ? "Needs retry" : download.error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .frame(maxWidth: 320, alignment: .trailing)
            }

            Button {
                vm.cancelDownload(key: download.key)
            } label: {
                Label("Remove", systemImage: "trash")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(minWidth: 110)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Micro Components

    private func sectionHeader(_ title: String, count: Int, tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.black)
                .textCase(.uppercase)
                .foregroundStyle(tint)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.black)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tint.opacity(0.9), in: Capsule())

            Spacer()
        }
        .padding(.top, 2)
    }

    private func metricPill(label: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3)
                .fontWeight(.black)
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func metadataPills(_ download: ParsedDownload) -> some View {
        if let year = download.year {
            detailPill(year, tint: .gray)
        }
        if let season = download.season, let episode = download.episode {
            detailPill("S\(season.leftPadded(2))E\(episode.leftPadded(2))", tint: .purple)
        }
        if let language = download.language {
            detailPill(language, tint: .orange)
        }
    }

    private func detailPill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.82), in: Capsule())
    }

    private func mediaTypeBadge(_ type: DownloadMediaType) -> some View {
        Text(typeLabel(type))
            .font(.caption)
            .fontWeight(.black)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(type == .movie ? Color.indigo : Color.teal, in: Capsule())
    }

    private func statusBadge(_ text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }

    private func activeCardBackground(_ download: ParsedDownload) -> some ShapeStyle {
        LinearGradient(
            colors: [statusColor(download).opacity(0.26), Color.white.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Helpers

    private func sectionTint(for filter: DownloadFilter) -> Color {
        switch filter {
        case .all: .white
        case .active: Theme.accent
        case .completed: .green
        case .failed: .orange
        }
    }

    private func statusColor(_ download: ParsedDownload) -> Color {
        ColorUtils.statusColor(download.status)
    }

    private func iconName(_ download: ParsedDownload) -> String {
        if download.isCompleted { return "checkmark.circle.fill" }
        if download.isFailed { return "exclamationmark.triangle.fill" }
        return "arrow.down.circle.fill"
    }

    private func iconColor(_ download: ParsedDownload) -> Color {
        if download.isCompleted { return .green }
        if download.isFailed { return .orange }
        return Theme.accent
    }

    private func typeLabel(_ type: DownloadMediaType) -> String {
        switch type {
        case .movie: "Movie"
        case .tv: "TV"
        case .unknown: "Media"
        }
    }

    private func clampedPercent(_ value: Double) -> Double {
        max(0, min(100, value))
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

private extension String {
    func leftPadded(_ length: Int) -> String {
        let pad = length - count
        return pad > 0 ? String(repeating: "0", count: pad) + self : self
    }
}
