import Foundation
import Observation

// MARK: - TabItem

@Observable
final class TabItem: Identifiable {

    // MARK: Stored properties
    var id: UUID
    var title: String
    var currentURL: URL?
    var faviconSystemImage: String
    var isPersonalStudy: Bool
    var createdAt: Date
    var lastAccessedAt: Date

    // Runtime-only (not persisted)
    var canGoBack:    Bool = false
    var canGoForward: Bool = false
    var isLoading:    Bool = false
    var isReaderMode: Bool = false

    // MARK: Init
    init(
        id: UUID = UUID(),
        title: String = "New Tab",
        currentURL: URL? = nil,
        faviconSystemImage: String = "safari",
        isPersonalStudy: Bool = false,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.currentURL = currentURL
        self.faviconSystemImage = faviconSystemImage
        self.isPersonalStudy = isPersonalStudy
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
    }
}

// MARK: - TabItem Codable support (manual, excludes runtime-only props)

extension TabItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, currentURL, faviconSystemImage, isPersonalStudy, createdAt, lastAccessedAt
    }

    convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id                = try c.decode(UUID.self,   forKey: .id)
        let title             = try c.decode(String.self, forKey: .title)
        let urlString         = try c.decodeIfPresent(String.self, forKey: .currentURL)
        let currentURL        = urlString.flatMap { URL(string: $0) }
        let faviconSystemImage = try c.decode(String.self, forKey: .faviconSystemImage)
        let isPersonalStudy   = try c.decode(Bool.self,   forKey: .isPersonalStudy)
        let createdAt         = try c.decode(Date.self,   forKey: .createdAt)
        let lastAccessedAt    = try c.decode(Date.self,   forKey: .lastAccessedAt)
        self.init(
            id: id,
            title: title,
            currentURL: currentURL,
            faviconSystemImage: faviconSystemImage,
            isPersonalStudy: isPersonalStudy,
            createdAt: createdAt,
            lastAccessedAt: lastAccessedAt
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                    forKey: .id)
        try c.encode(title,                 forKey: .title)
        try c.encodeIfPresent(currentURL?.absoluteString, forKey: .currentURL)
        try c.encode(faviconSystemImage,    forKey: .faviconSystemImage)
        try c.encode(isPersonalStudy,       forKey: .isPersonalStudy)
        try c.encode(createdAt,             forKey: .createdAt)
        try c.encode(lastAccessedAt,        forKey: .lastAccessedAt)
    }
}
