import Foundation

struct CategoryOption: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let censored: Bool
    let genres: [Genre]?
}
