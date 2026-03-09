import Foundation
import SwiftData

// MARK: - Note (SwiftData)

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var publicationURL: String?
    var verseReference: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        publicationURL: String? = nil,
        verseReference: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.publicationURL = publicationURL
        self.verseReference = verseReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
