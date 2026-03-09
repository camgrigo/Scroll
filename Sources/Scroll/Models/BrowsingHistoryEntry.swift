import Foundation
import SwiftData

// MARK: - BrowsingHistoryEntry (SwiftData)

@Model
final class BrowsingHistoryEntry {
    var id: UUID
    var title: String
    var url: String
    var visitedAt: Date
    var faviconSystemImage: String

    init(
        id: UUID = UUID(),
        title: String = "",
        url: String = "",
        visitedAt: Date = Date(),
        faviconSystemImage: String = "safari"
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.visitedAt = visitedAt
        self.faviconSystemImage = faviconSystemImage
    }
}
