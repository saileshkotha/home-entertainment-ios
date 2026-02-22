import Foundation

enum LanguageMap {
    private static let map: [String: String] = [
        "te": "Telugu",
        "en": "English",
        "hi": "Hindi",
        "ta": "Tamil",
        "ml": "Malayalam",
        "kn": "Kannada",
        "bn": "Bengali",
        "pa": "Punjabi",
        "mr": "Marathi",
        "gu": "Gujarati",
        "ur": "Urdu",
        "fr": "French",
        "si": "Sinhala",
    ]

    static func name(for code: String) -> String {
        map[code] ?? code.uppercased()
    }
}
