import Foundation

enum AppConstants {
    static let baseURL = "http://192.168.68.67:5001"
    static let defaultCategoryId = 14
    static let pageSize = 24
    static let downloadPollInterval: TimeInterval = 6
    static let liveLinkRetryDelays: [UInt64] = [1_000_000_000, 2_000_000_000, 3_000_000_000, 4_000_000_000]
}
