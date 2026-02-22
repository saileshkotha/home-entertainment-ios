import SwiftUI

struct LinkActionsView: View {
    let rowKey: String
    let activeLink: TVViewModel.ActiveLink?
    let isLoading: Bool
    let isDownloading: Bool
    let onGenerate: () -> Void
    let onDownloadToPlex: () -> Void

    @State private var toast: String?

    private var isActive: Bool { activeLink?.key == rowKey }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                onGenerate()
            } label: {
                if isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Label(
                        isActive ? "Regenerate" : "Get Link",
                        systemImage: isActive ? "arrow.clockwise" : "link"
                    )
                    .fontWeight(.medium)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(Theme.accent)
            .disabled(isLoading || isDownloading)

            if isActive, let link = activeLink {
                Button {
                    UIPasteboard.general.string = link.url
                    showToast("Copied!")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    if let url = URL(string: link.url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(.green)

                Button {
                    onDownloadToPlex()
                } label: {
                    if isDownloading {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Plex", systemImage: "arrow.down.to.line")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Theme.downloads)
                .disabled(isDownloading)
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
                    .offset(y: -30)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
    }

    private func showToast(_ message: String) {
        toast = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if toast == message { toast = nil }
        }
    }
}
