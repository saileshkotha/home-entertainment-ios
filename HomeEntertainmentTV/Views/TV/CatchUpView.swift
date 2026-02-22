import SwiftUI

struct ArchiveDate: Identifiable {
    let id: Int
    let date: Date
}

struct DateStripView: View {
    let dates: [ArchiveDate]
    let selectedDate: Date
    let onSelect: (Date) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dates) { item in
                    dateButton(item)
                }
            }
        }
    }

    @ViewBuilder
    private func dateButton(_ item: ArchiveDate) -> some View {
        let isSelected = Calendar.current.isDate(item.date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(item.date)

        Button {
            onSelect(item.date)
        } label: {
            VStack(spacing: 4) {
                Text(item.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.callout)
                    .fontWeight(isSelected ? .bold : .regular)
                Text(isToday ? "Today" : item.date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(minWidth: 100)
            .padding(.vertical, 12)
        }
        .if(isSelected) { $0.buttonStyle(.borderedProminent).tint(Theme.accent) }
        .if(!isSelected) { $0.buttonStyle(.bordered) }
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct CatchUpView: View {
    var vm: LiveTVViewModel
    let channel: TvChannel
    @State private var showPlayer = false

    private let timeFormat: Date.FormatStyle = .dateTime.hour().minute()

    private var archiveDates: [ArchiveDate] {
        let range = channel.archiveRange ?? 7
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<range).compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return ArchiveDate(id: offset, date: d)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Catch Up — \(channel.name)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 60)

            DateStripView(dates: archiveDates, selectedDate: vm.catchupDate) { date in
                vm.catchupDate = date
                vm.loadGuide()
            }
            .padding(.horizontal, 60)

            if vm.isLoadingGuide {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if vm.guide.isEmpty {
                ContentUnavailableView {
                    Label("No programs", systemImage: "calendar.badge.exclamationmark")
                } description: {
                    Text("No programs found for this date")
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                programList
            }
        }
        .padding(.vertical, 30)
        .navigationTitle("Catch Up")
        .fullScreenCover(isPresented: $showPlayer) {
            if let link = vm.activeLink, let url = URL(string: link.url) {
                VideoPlayerView(url: url)
            }
        }
    }

    private var programList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(vm.guide) { program in
                    programRow(program)
                }
            }
        }
    }

    private func programRow(_ program: TvProgram) -> some View {
        let rowKey = "catchup-\(channel.id)-\(program.id)"

        return VStack(spacing: 0) {
            HStack(spacing: 20) {
                Text(program.startDate.formatted(timeFormat))
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)

                Text(program.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Spacer()

                Button {
                    vm.fetchCatchupLink(program: program)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if vm.activeLink?.key == rowKey { showPlayer = true }
                    }
                } label: {
                    Label("Watch", systemImage: "play.fill")
                }
                .disabled(vm.isLoadingLink)

                Button {
                    vm.fetchCatchupLink(program: program)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        vm.downloadToPlex(
                            rowKey: rowKey,
                            fileName: FileNameFormatter.catchupFileName(
                                channelName: channel.name,
                                programName: program.name,
                                startUnix: program.start
                            )
                        )
                    }
                } label: {
                    Label("Plex", systemImage: "arrow.down.to.line")
                }
                .disabled(vm.isDownloading)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 14)

            Divider()
                .padding(.horizontal, 60)
        }
    }
}
