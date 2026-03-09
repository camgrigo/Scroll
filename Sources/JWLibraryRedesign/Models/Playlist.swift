import Foundation
import SwiftData

// MARK: - Playlist (SwiftData)

@Model
final class Playlist {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var items: [PlaylistItem]

    init(
        id: UUID = UUID(),
        name: String = "New Playlist",
        createdAt: Date = Date(),
        items: [PlaylistItem] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }
}

// MARK: - PlaylistItem (SwiftData)

@Model
final class PlaylistItem {
    var id: UUID
    var title: String
    var url: String
    var type: String    // "audio","video","reading"
    var order: Int
    var playlist: Playlist?

    init(
        id: UUID = UUID(),
        title: String = "",
        url: String = "",
        type: String = "reading",
        order: Int = 0,
        playlist: Playlist? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.type = type
        self.order = order
        self.playlist = playlist
    }
}
