import Foundation

enum FileNameFormatter {

    static func movieFileName(name: String, year: Int) -> String {
        let safeName = name.replacingOccurrences(of: ":", with: "-")
        return "Videos/\(safeName) (\(year)).mp4"
    }

    static func episodeFileName(
        seriesName: String,
        seasonNumber: Int,
        episodeNumber: Int,
        episodeName: String,
        language: String? = nil
    ) -> String {
        let safeName = seriesName.replacingOccurrences(of: ":", with: "-")
        let s = String(format: "%02d", seasonNumber)
        let e = String(format: "%02d", episodeNumber)
        let lang = language.map { " \(LanguageMap.name(for: $0))" } ?? ""
        return "TVShows/\(safeName) - s\(s)e\(e) -\(lang) \(episodeName).mp4"
    }

    static func liveFileName(channelName: String) -> String {
        let safeName = sanitize(channelName)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let stamp = formatter.string(from: Date())
        return "TVShows/\(safeName) - Live - \(stamp).mp4"
    }

    static func catchupFileName(channelName: String, programName: String, startUnix: Int) -> String {
        let safeChannel = sanitize(channelName)
        let safeProgram = sanitize(programName)
        let date = Date(timeIntervalSince1970: TimeInterval(startUnix))
        let calendar = Calendar.current
        let month = String(format: "%02d", calendar.component(.month, from: date))
        let day = String(format: "%02d", calendar.component(.day, from: date))
        return "TVShows/\(safeChannel) - s\(month)e\(day) - \(safeProgram).mp4"
    }

    private static func sanitize(_ value: String) -> String {
        let illegal = CharacterSet(charactersIn: "<>:\"/\\|?*")
            .union(.controlCharacters)
        let cleaned = value.unicodeScalars
            .filter { !illegal.contains($0) }
            .map(String.init)
            .joined()
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "Unknown" : cleaned
    }
}
