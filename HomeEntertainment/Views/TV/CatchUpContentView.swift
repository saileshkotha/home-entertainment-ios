import SwiftUI

struct CatchUpContentView: View {
    @Bindable var vm: TVViewModel

    private let timeFormat: Date.FormatStyle = .dateTime.month(.abbreviated).day().hour().minute()

    var body: some View {
        if let channel = vm.selectedChannel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(channel.genre.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    DatePicker("", selection: $vm.catchupDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: vm.catchupDate) { _, _ in
                            vm.loadGuide()
                        }
                }

                if vm.isLoadingGuide {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if vm.guide.isEmpty {
                    ContentUnavailableView {
                        Label("No programs", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("No programs found for this date")
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.guide) { program in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(program.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                HStack(spacing: 16) {
                                    Label(program.startDate.formatted(timeFormat), systemImage: "play.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Label(program.endDate.formatted(timeFormat), systemImage: "stop.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                let rowKey = "catchup-\(channel.id)-\(program.id)"
                                LinkActionsView(
                                    rowKey: rowKey,
                                    activeLink: vm.activeLink,
                                    isLoading: vm.isLoadingLink && vm.activeLink == nil,
                                    isDownloading: vm.isDownloading,
                                    onGenerate: { vm.fetchCatchupLink(program: program) },
                                    onDownloadToPlex: {
                                        vm.downloadToPlex(
                                            rowKey: rowKey,
                                            fileName: FileNameFormatter.catchupFileName(
                                                channelName: channel.name,
                                                programName: program.name,
                                                startUnix: program.start
                                            )
                                        )
                                    }
                                )
                            }
                            .padding(10)
                            .glassEffect(in: .rect(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding()
        } else {
            ContentUnavailableView {
                Label("Select a channel", systemImage: "tv")
                    .foregroundStyle(Theme.tv)
            } description: {
                Text("Pick a channel to get started")
            }
        }
    }
}
