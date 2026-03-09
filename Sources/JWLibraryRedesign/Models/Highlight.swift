import Foundation
import SwiftData

// MARK: - Highlight (SwiftData)

@Model
final class Highlight {
    var id: UUID
    var publicationURL: String
    var selectedText: String
    var colorName: String   // "yellow","orange","pink","blue","purple","green"
    var pageTitle: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        publicationURL: String = "",
        selectedText: String = "",
        colorName: String = "yellow",
        pageTitle: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.publicationURL = publicationURL
        self.selectedText = selectedText
        self.colorName = colorName
        self.pageTitle = pageTitle
        self.createdAt = createdAt
    }
}
