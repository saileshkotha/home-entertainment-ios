import Foundation

struct TvChannel: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let number: Int?
    let genre: Category
    let archive: Bool?
    let archiveRange: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, number, genre, archive
        case archiveRange = "archive_range"
    }

    var hasArchive: Bool { archive ?? false }
}

struct TvProgram: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let start: Int
    let end: Int

    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(start)) }
    var endDate: Date { Date(timeIntervalSince1970: TimeInterval(end)) }
}
