import SwiftUI

struct LiveContentView: View {
    @Bindable var vm: TVViewModel

    var body: some View {
        if let channel = vm.selectedChannel {
            VStack(alignment: .leading, spacing: 14) {
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

                    if channel.hasArchive {
                        Label("Catch up", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.purple, in: .capsule)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Live Actions", systemImage: "dot.radiowaves.left.and.right")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.tv)

                    LinkActionsView(
                        rowKey: "live-\(channel.id)",
                        activeLink: vm.activeLink,
                        isLoading: vm.isLoadingLink,
                        isDownloading: vm.isDownloading,
                        onGenerate: { vm.fetchLiveLink() },
                        onDownloadToPlex: {
                            vm.downloadToPlex(
                                rowKey: "live-\(channel.id)",
                                fileName: FileNameFormatter.liveFileName(channelName: channel.name)
                            )
                        }
                    )
                }
                .padding(12)
                .glassEffect(in: .rect(cornerRadius: 12))
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
