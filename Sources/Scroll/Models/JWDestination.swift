import SwiftUI

// MARK: - JWDestination

enum JWDestination: String, CaseIterable, Identifiable {
    case dailyText
    case bible
    case meetingMaterials
    case meetingPublications
    case favorites
    case whatsNew
    case toolbox
    case fullLibrary

    var id: String { rawValue }

    // MARK: Display

    var title: String {
        switch self {
        case .dailyText:          return "Daily Text"
        case .bible:              return "Bible"
        case .meetingMaterials:   return "Meeting Materials"
        case .meetingPublications: return "Meeting Workbook"
        case .favorites:          return "Favorites"
        case .whatsNew:           return "What's New"
        case .toolbox:            return "Teaching Toolbox"
        case .fullLibrary:        return "Full Library"
        }
    }

    var subtitle: String {
        switch self {
        case .dailyText:          return "Read today's scripture"
        case .bible:              return "Study the scriptures"
        case .meetingMaterials:   return "This week's program"
        case .meetingPublications: return "CLAM workbook"
        case .favorites:          return "Saved articles & verses"
        case .whatsNew:           return "Latest publications"
        case .toolbox:            return "Bible study aids"
        case .fullLibrary:        return "Browse all publications"
        }
    }

    var systemImage: String {
        switch self {
        case .dailyText:          return "sun.max.fill"
        case .bible:              return "book.fill"
        case .meetingMaterials:   return "person.3.fill"
        case .meetingPublications: return "doc.text.fill"
        case .favorites:          return "star.fill"
        case .whatsNew:           return "sparkles"
        case .toolbox:            return "wrench.and.screwdriver.fill"
        case .fullLibrary:        return "books.vertical.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .dailyText:          return Color(hex: "#F9A825")
        case .bible:              return Color(hex: "#1565C0")
        case .meetingMaterials:   return Color(hex: "#2E7D32")
        case .meetingPublications: return Color(hex: "#6A1B9A")
        case .favorites:          return Color(hex: "#E53935")
        case .whatsNew:           return Color(hex: "#00838F")
        case .toolbox:            return Color(hex: "#4E342E")
        case .fullLibrary:        return Color(hex: "#37474F")
        }
    }

    var url: URL {
        switch self {
        case .dailyText:
            return URL(string: "https://www.jw.org/en/library/daily-text/")!
        case .bible:
            return URL(string: "https://www.jw.org/en/library/bible/")!
        case .meetingMaterials:
            return MeetingMaterialsService.currentWorkbookURL()
        case .meetingPublications:
            return URL(string: "https://www.jw.org/en/library/jw-meeting-workbook/")!
        case .favorites:
            return URL(string: "https://www.jw.org/en/library/")!
        case .whatsNew:
            return URL(string: "https://www.jw.org/en/library/?pub=latest")!
        case .toolbox:
            return URL(string: "https://www.jw.org/en/teaching-tools/")!
        case .fullLibrary:
            return URL(string: "https://www.jw.org/en/library/")!
        }
    }
}
