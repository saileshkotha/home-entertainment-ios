import SwiftUI

struct DownloadRowView: View {
    let download: ParsedDownload
    let onDelete: () -> Void
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if !compact {
                ProgressRingView(
                    percent: download.percentCompleted,
                    size: download.isActive ? 56 : 42
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(download.displayName)
                        .font(compact ? .subheadline : .body)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if let year = download.year {
                        pill(year, color: .gray)
                    }

                    if let s = download.season, let e = download.episode {
                        pill("S\(s.leftPadded(2))E\(e.leftPadded(2))", color: .purple)
                    }

                    if let lang = download.language {
                        pill(lang, color: .orange)
                    }
                }

                HStack(spacing: 6) {
                    Text(download.type == .movie ? "Movie" : "TV")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            download.isActive
                                ? ColorUtils.statusColor(download.status)
                                : ColorUtils.statusColor(download.status).opacity(0.12),
                            in: Capsule()
                        )
                        .foregroundStyle(download.isActive ? .white : ColorUtils.statusColor(download.status))

                    HStack(spacing: 3) {
                        Circle()
                            .fill(ColorUtils.statusColor(download.status))
                            .frame(width: 6, height: 6)
                        Text(download.status)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if compact {
                        Text("\(Int(download.percentCompleted))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !download.error.isEmpty && download.error != "None" {
                    Text(download.error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button("Clear", role: .destructive) { onDelete() }
                .font(compact ? .caption : .subheadline)
                .buttonStyle(.borderless)
        }
        .padding(compact ? 10 : 14)
        .glassEffect(
            download.isActive
                ? .regular.tint(.blue)
                : .regular,
            in: .rect(cornerRadius: 12)
        )
    }

    private func pill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.75), in: Capsule())
    }
}

private extension String {
    func leftPadded(_ length: Int) -> String {
        let pad = length - count
        return pad > 0 ? String(repeating: "0", count: pad) + self : self
    }
}
