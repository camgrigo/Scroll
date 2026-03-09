import Foundation
import Observation

// MARK: - Model

struct DailyTextData: Codable {
    let dateString: String      // e.g. "Monday, March 9"
    let themeScripture: String  // e.g. "\"will come true.\"—Ezek. 33:33."
    let fetchedOn: Date         // used to detect stale cache

    var isStale: Bool {
        !Calendar.current.isDateInToday(fetchedOn)
    }
}

// MARK: - Service

@Observable
final class DailyTextService {

    var data: DailyTextData? = nil
    var isLoading = false
    var fetchFailed = false

    private let cacheKey = "jwl_dailyText_cache"

    // MARK: - Init

    init() { loadCached() }

    // MARK: - Public

    @MainActor
    func fetchIfNeeded() async {
        if let d = data, !d.isStale { return }
        await fetch()
    }

    // MARK: - Fetch

    @MainActor
    private func fetch() async {
        isLoading = true
        fetchFailed = false

        let today = Date()
        let cal = Calendar.current
        let y = cal.component(.year,  from: today)
        let m = cal.component(.month, from: today)
        let d = cal.component(.day,   from: today)

        // Watchtower Online Library daily-text endpoint (HTML, public)
        let urlString = "https://wol.jw.org/en/wol/dt/r1/lp-e/\(y)/\(m)/\(d)"
        guard let url = URL(string: urlString) else { finish(nil); return }

        do {
            let (rawData, _) = try await URLSession.shared.data(from: url)
            let html = String(data: rawData, encoding: .utf8) ?? ""
            let parsed = parse(html: html, fallbackDate: today)
            finish(parsed)
        } catch {
            finish(nil)
        }
    }

    @MainActor
    private func finish(_ result: DailyTextData?) {
        isLoading = false
        if let result {
            data = result
            persist(result)
        } else {
            fetchFailed = true
            // If nothing cached yet, build a date-only fallback
            if data == nil {
                data = DailyTextData(
                    dateString: Self.formatDate(Date()),
                    themeScripture: "",
                    fetchedOn: Date()
                )
            }
        }
    }

    // MARK: - HTML parsing

    private func parse(html: String, fallbackDate: Date) -> DailyTextData? {
        let dateStr  = extractDate(from: html)  ?? Self.formatDate(fallbackDate)
        let scripture = extractTheme(from: html) ?? ""
        return DailyTextData(dateString: dateStr, themeScripture: scripture, fetchedOn: fallbackDate)
    }

    /// Pulls the date string from WOL HTML.
    /// WOL wraps it in <h2> or a span with class "contextDateString".
    private func extractDate(from html: String) -> String? {
        let patterns = [
            // WOL: <h2 …><strong>Monday, March 9</strong>
            "<h2[^>]*>[\\s\\S]*?<strong[^>]*>([^<]+)</strong>",
            // WOL alternate: contextDateString span
            "class=\"contextDateString\"[^>]*>([^<]+)<",
            // Bare h2
            "<h2[^>]*>([^<]+)</h2>",
        ]
        for pattern in patterns {
            if let m = html.firstCapture(pattern: pattern) {
                let s = m.stripHTML().collapseWhitespace()
                if s.count > 3 { return s }
            }
        }
        return nil
    }

    /// Pulls the theme scripture from WOL HTML.
    private func extractTheme(from html: String) -> String? {
        let patterns = [
            // WOL: class="themeScrp"
            "class=\"themeScrp\"[^>]*>([\\s\\S]*?)</p>",
            // WOL alternate: dc-bleedToArticle first paragraph after h2
            "<p[^>]+data-pid=\"2\"[^>]*>([\\s\\S]*?)</p>",
            // Fallback: first <em> content (often the quoted text)
            "<em>([^<]+)</em>",
        ]
        for pattern in patterns {
            if let m = html.firstCapture(pattern: pattern) {
                let s = m.stripHTML().collapseWhitespace()
                if s.count > 3 { return s }
            }
        }
        return nil
    }

    // MARK: - Cache

    private func persist(_ dt: DailyTextData) {
        if let encoded = try? JSONEncoder().encode(dt) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    private func loadCached() {
        guard
            let raw = UserDefaults.standard.data(forKey: cacheKey),
            let cached = try? JSONDecoder().decode(DailyTextData.self, from: raw),
            !cached.isStale
        else { return }
        data = cached
    }

    // MARK: - Helpers

    static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }
}

// MARK: - String helpers

private extension String {
    /// Returns the first capture group of a regex pattern.
    func firstCapture(pattern: String) -> String? {
        guard
            let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.dotMatchesLineSeparators, .caseInsensitive]
            ),
            let match = regex.firstMatch(
                in: self,
                range: NSRange(startIndex..., in: self)
            ),
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: self)
        else { return nil }
        return String(self[range])
    }

    /// Strips HTML tags.
    func stripHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// Collapses runs of whitespace/newlines into a single space.
    func collapseWhitespace() -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
