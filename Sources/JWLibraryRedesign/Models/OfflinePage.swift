import Foundation
import SwiftData

// MARK: - OfflinePage (SwiftData)

@Model
final class OfflinePage {
    var id: UUID
    var url: String
    var title: String
    var savedDate: Date
    var lastAccessedDate: Date
    var fileSize: Int64      // bytes

    init(id: UUID = UUID(), url: String, title: String, fileSize: Int64 = 0) {
        self.id = id
        self.url = url
        self.title = title
        self.savedDate = Date()
        self.lastAccessedDate = Date()
        self.fileSize = fileSize
    }

    /// Relative path inside the OfflinePages directory
    var filePath: String { "\(id.uuidString).webarchive" }

    var fileSizeFormatted: String {
        let mb = Double(fileSize) / 1_048_576
        return mb >= 1 ? String(format: "%.1f MB", mb) : "\(fileSize / 1024) KB"
    }
}
