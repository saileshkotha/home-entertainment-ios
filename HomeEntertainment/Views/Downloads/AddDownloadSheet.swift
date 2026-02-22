import SwiftUI

struct AddDownloadSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (String, String) -> Void

    @State private var mediaType = "movie"
    @State private var m3u8Url = ""
    @State private var movieName = ""
    @State private var movieYear = ""
    @State private var tvSeriesName = ""
    @State private var season = ""
    @State private var episode = ""

    private var isValid: Bool {
        guard !m3u8Url.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if mediaType == "movie" {
            return !movieName.trimmingCharacters(in: .whitespaces).isEmpty
                && !movieYear.trimmingCharacters(in: .whitespaces).isEmpty
                && Int(movieYear) != nil
        } else {
            return !tvSeriesName.trimmingCharacters(in: .whitespaces).isEmpty
                && !season.trimmingCharacters(in: .whitespaces).isEmpty
                && !episode.trimmingCharacters(in: .whitespaces).isEmpty
                && Int(season) != nil
                && Int(episode) != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("M3U8 URL", text: $m3u8Url)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Picker("Type", selection: $mediaType) {
                        Text("Movie").tag("movie")
                        Text("TV Series").tag("tv")
                    }
                    .pickerStyle(.segmented)
                }

                if mediaType == "movie" {
                    Section("Movie Details") {
                        TextField("Movie Name", text: $movieName)
                        TextField("Year", text: $movieYear)
                            .keyboardType(.numberPad)
                    }
                } else {
                    Section("TV Series Details") {
                        TextField("Series Name", text: $tvSeriesName)
                        TextField("Season", text: $season)
                            .keyboardType(.numberPad)
                        TextField("Episode", text: $episode)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Add Download")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { submit() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() {
        let fileName: String
        if mediaType == "movie" {
            let title = toTitleCase(movieName)
            fileName = "Videos/\(title) (\(movieYear)).mp4"
        } else {
            let title = toTitleCase(tvSeriesName)
            let s = season.leftPadded(2)
            let e = episode.leftPadded(2)
            fileName = "TVShows/\(title) - s\(s)e\(e).mp4"
        }

        onSubmit(m3u8Url.trimmingCharacters(in: .whitespaces), fileName)
        dismiss()
    }

    private func toTitleCase(_ str: String) -> String {
        str.trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

private extension String {
    func leftPadded(_ length: Int) -> String {
        let pad = length - count
        return pad > 0 ? String(repeating: "0", count: pad) + self : self
    }
}
