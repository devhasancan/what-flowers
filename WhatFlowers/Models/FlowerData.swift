import Foundation

struct FlowerData: Codable {
    let query: Query
}

struct Query: Codable {
    let pageids: [String]
    let pages: [String: Page]
}

struct Page: Codable {
    let title: String
    let extract: String?
    let thumbnail: Thumbnail?
}

struct Thumbnail: Codable {
    let source: String
}







