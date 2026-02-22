import SwiftUI

struct ActionButtonsView: View {
    let movieId: Int
    let fileId: Int
    let downloadFileName: String
    var compact: Bool = false

    @State private var link: String?
    @State private var isLoadingLink = false
    @State private var isDownloading = false
    @State private var toast: String?

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            Button {
                Task { await getLink() }
            } label: {
                if isLoadingLink {
                    ProgressView().controlSize(.small)
                } else {
                    Label(
                        link != nil ? "Regenerate" : "Get Link",
                        systemImage: link != nil ? "arrow.clockwise" : "link"
                    )
                    .fontWeight(.medium)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .regular)
            .tint(Theme.accent)
            .disabled(isLoadingLink || isDownloading)

            Button {
                Task { await downloadToPlex() }
            } label: {
                if isDownloading {
                    ProgressView().controlSize(.small)
                } else {
                    Label(
                        compact ? "Plex" : "Plex Download",
                        systemImage: "arrow.down.to.line"
                    )
                    .fontWeight(.medium)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(compact ? .small : .regular)
            .tint(Theme.downloads)
            .disabled(isLoadingLink || isDownloading)

            if let link {
                Button {
                    UIPasteboard.general.string = link
                    showToast("Copied!")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(compact ? .small : .regular)

                Button {
                    if let url = URL(string: link) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(compact ? .small : .regular)
                .tint(.green)
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .glassEffect(in: .capsule)
                    .offset(y: -28)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
    }

    private func getLink() async {
        isLoadingLink = true
        do {
            let url = try await MovieService.getLink(movieId: movieId, fileId: fileId)
            link = url
            showToast("Link ready")
        } catch {
            showToast("Failed")
        }
        isLoadingLink = false
    }

    private func downloadToPlex() async {
        isDownloading = true
        do {
            var url = link
            if url == nil {
                url = try await MovieService.getLink(movieId: movieId, fileId: fileId)
                link = url
            }
            if let url {
                try await DownloadService.startDownload(fileName: downloadFileName, url: url, movieId: movieId, fileId: fileId)
                showToast("Download started")
            }
        } catch {
            showToast("Download failed")
        }
        isDownloading = false
    }

    private func showToast(_ message: String) {
        toast = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if toast == message { toast = nil }
        }
    }
}
