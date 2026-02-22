import Foundation

struct Quality: Decodable, Hashable {
    let id: Int
    let code: String
    let name: String
    let width: Int
}

struct MediaFile: Decodable, Identifiable, Hashable {
    let id: Int
    let type: String
    let mediaId: Int
    let url: String
    let quality: Quality
    let languages: [String]
    let watchedStatus: String

    enum CodingKeys: String, CodingKey {
        case id, type, url, quality, languages
        case mediaId = "media_id"
        case watchedStatus = "watched_status"
    }
}

struct Category: Decodable, Hashable {
    let id: Int
    let name: String
    let censored: Bool
}

struct Genre: Decodable, Identifiable, Hashable {
    let id: GenreID
    let name: String

    // API returns genre id as either Int or String depending on context
    enum GenreID: Decodable, Hashable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                self = .int(intVal)
            } else if let strVal = try? container.decode(String.self) {
                self = .string(strVal)
            } else {
                throw DecodingError.typeMismatch(
                    GenreID.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected Int or String")
                )
            }
        }

        var stringValue: String {
            switch self {
            case .int(let v): String(v)
            case .string(let v): v
            }
        }
    }
}

struct Movie: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let originalName: String
    let description: String
    let director: String
    let actors: String
    let year: Int
    let yearEnd: Int
    let country: String
    let duration: Int
    let isTvSeries: Bool
    let category: Category
    let genres: [Genre]
    let censored: Bool
    let age: String
    let ratingMpaa: String
    let cover: String
    let screenshots: [String]
    let added: Int
    let favorite: Bool
    let ratingKinopoisk: Double
    let ratingImdb: Double
    let watchedStatus: String
    let files: [MediaFile]

    enum CodingKeys: String, CodingKey {
        case id, name, description, director, actors, year, country, duration
        case category, genres, censored, age, cover, screenshots, added, favorite, files
        case originalName = "original_name"
        case yearEnd = "year_end"
        case isTvSeries = "is_tv_series"
        case ratingMpaa = "rating_mpaa"
        case ratingKinopoisk = "rating_kinopoisk"
        case ratingImdb = "rating_imdb"
        case watchedStatus = "watched_status"
    }

    static func == (lhs: Movie, rhs: Movie) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Season: Decodable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let name: String
    let originalName: String
    let added: Int
    let watchedStatus: String

    enum CodingKeys: String, CodingKey {
        case id, number, name, added
        case originalName = "original_name"
        case watchedStatus = "watched_status"
    }
}

struct Episode: Decodable, Identifiable, Hashable {
    let id: Int
    let number: Int
    let name: String
    let originalName: String
    let seasonId: Int
    let qualities: [Int]
    let languages: [String]
    let subtitles: [String]
    let files: [MediaFile]
    let added: Int

    enum CodingKeys: String, CodingKey {
        case id, number, name, qualities, languages, subtitles, files, added
        case originalName = "original_name"
        case seasonId = "season_id"
    }

    static func == (lhs: Episode, rhs: Episode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
