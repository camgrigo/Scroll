import Foundation

// MARK: - MeetingMaterialsService

struct MeetingMaterialsService {

    // MARK: - Public API

    /// Returns URL for this week's CLAM workbook article.
    static func currentWorkbookURL() -> URL {
        let monday = mondayOfCurrentWeek()
        let cal = Calendar.current
        let month = cal.component(.month, from: monday)
        let year  = cal.component(.year,  from: monday)
        let slug  = bimonthlySlug(month: month)
        let urlString = "https://www.jw.org/en/library/jw-meeting-workbook/\(slug)-\(year)-mwb/"
        return URL(string: urlString)
            ?? URL(string: "https://www.jw.org/en/library/jw-meeting-workbook/")!
    }

    /// Returns URL for the Study Watchtower magazine landing page.
    static func currentStudyWatchtowerURL() -> URL {
        return URL(string: "https://www.jw.org/en/library/magazines/watchtower-study/")!
    }

    /// Returns both URLs as a named tuple.
    static func thisWeekMaterials() -> (workbook: URL, watchtower: URL) {
        return (workbook: currentWorkbookURL(), watchtower: currentStudyWatchtowerURL())
    }

    // MARK: - Private helpers

    /// Returns the Monday of the week containing today.
    private static func mondayOfCurrentWeek(from date: Date = Date()) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2   // Monday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date
    }

    /// Maps a month number to a bimonthly period slug, e.g. 3 -> "march-april".
    private static func bimonthlySlug(month: Int) -> String {
        switch month {
        case 1, 2:  return "january-february"
        case 3, 4:  return "march-april"
        case 5, 6:  return "may-june"
        case 7, 8:  return "july-august"
        case 9, 10: return "september-october"
        default:    return "november-december"
        }
    }
}
