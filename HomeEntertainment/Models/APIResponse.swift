import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let data: T
    let paging: PagingInfo?
    let generatedIn: Double?
    let timestamp: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case paging
        case generatedIn = "generated_in"
        case timestamp
    }
}

struct PagingInfo: Decodable {
    let limit: Int
    let offset: Int
    let total: Int
    let defaultLimit: Int?
    let maximumLimit: Int?
}

struct LinkData: Decodable {
    let url: String
}
