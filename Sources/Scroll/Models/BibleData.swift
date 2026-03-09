import Foundation

// MARK: - BibleBook

struct BibleBook: Identifiable, Hashable {
    let id: Int               // 1-based canonical number
    let name: String
    let abbreviation: String
    let urlSlug: String       // JW.org URL segment, e.g. "1-samuel"
    let versesByChapter: [Int]

    var chapterCount: Int { versesByChapter.count }

    func verseCount(forChapter chapter: Int) -> Int {
        guard chapter >= 1, chapter <= versesByChapter.count else { return 1 }
        return versesByChapter[chapter - 1]
    }

    /// JW.org NWT Bible URL for a given chapter (and optional verse anchor).
    func jwOrgURL(chapter: Int, verse: Int? = nil) -> URL {
        var urlString = "https://www.jw.org/en/library/bible/nwt/books/\(urlSlug)/\(chapter)/"
        if let verse {
            // Anchor format: v{book}{chapter:3}{verse:3}
            let anchor = String(format: "v%d%03d%03d", id, chapter, verse)
            urlString += "#\(anchor)"
        }
        return URL(string: urlString)!
    }
}

// MARK: - BibleData

enum BibleData {
    static let books: [BibleBook] = [
        // ── Old Testament ──────────────────────────────────────────────
        BibleBook(id: 1,  name: "Genesis",         abbreviation: "Gen",  urlSlug: "genesis",
            versesByChapter: [31,25,24,26,32,22,24,22,29,32,32,20,18,24,21,16,27,33,38,18,34,24,20,67,34,35,46,22,35,43,55,32,20,31,29,43,36,30,23,23,57,38,34,34,28,34,31,22,33,26]),
        BibleBook(id: 2,  name: "Exodus",          abbreviation: "Ex",   urlSlug: "exodus",
            versesByChapter: [22,25,22,11,25,22,17,19,16,14,20,28,18,15,22,18,11,14,20,14,15,22,17,14,6,25,15,12,24,15,6,29,40,24,14,16,20,12,27,25]),
        BibleBook(id: 3,  name: "Leviticus",       abbreviation: "Lev",  urlSlug: "leviticus",
            versesByChapter: [17,16,17,35,19,30,38,36,24,20,47,8,59,57,33,34,16,30,37,27,24,33,44,23,55,46,34]),
        BibleBook(id: 4,  name: "Numbers",         abbreviation: "Num",  urlSlug: "numbers",
            versesByChapter: [54,34,51,49,31,27,89,26,23,36,35,16,33,45,41,50,13,32,22,29,35,41,30,25,18,65,23,31,39,17,54,42,56,29,34,13]),
        BibleBook(id: 5,  name: "Deuteronomy",     abbreviation: "Deut", urlSlug: "deuteronomy",
            versesByChapter: [46,37,29,49,33,25,26,20,29,22,32,32,18,29,23,22,20,22,21,20,23,30,25,22,19,19,26,68,29,20,30,52,29,12]),
        BibleBook(id: 6,  name: "Joshua",          abbreviation: "Josh", urlSlug: "joshua",
            versesByChapter: [18,24,17,24,15,27,26,35,27,43,23,24,33,15,63,10,18,28,51,9,45,34,16,33]),
        BibleBook(id: 7,  name: "Judges",          abbreviation: "Judg", urlSlug: "judges",
            versesByChapter: [36,23,31,24,31,40,25,35,57,18,40,15,25,20,20,31,13,31,30,48,25]),
        BibleBook(id: 8,  name: "Ruth",            abbreviation: "Ruth", urlSlug: "ruth",
            versesByChapter: [22,23,18,22]),
        BibleBook(id: 9,  name: "1 Samuel",        abbreviation: "1Sa",  urlSlug: "1-samuel",
            versesByChapter: [28,36,21,22,12,21,17,22,27,27,15,25,23,52,35,23,58,30,24,42,15,23,29,22,44,25,12,25,11,31,13]),
        BibleBook(id: 10, name: "2 Samuel",        abbreviation: "2Sa",  urlSlug: "2-samuel",
            versesByChapter: [27,32,39,12,25,23,29,18,13,19,27,31,39,33,37,23,29,33,43,26,22,51,39,25]),
        BibleBook(id: 11, name: "1 Kings",         abbreviation: "1Ki",  urlSlug: "1-kings",
            versesByChapter: [53,46,28,34,18,38,51,66,28,29,43,33,34,31,34,34,24,46,21,43,29,53]),
        BibleBook(id: 12, name: "2 Kings",         abbreviation: "2Ki",  urlSlug: "2-kings",
            versesByChapter: [18,25,27,44,27,33,20,29,37,36,21,21,25,29,38,20,41,37,37,21,26,20,37,20,30]),
        BibleBook(id: 13, name: "1 Chronicles",   abbreviation: "1Ch",  urlSlug: "1-chronicles",
            versesByChapter: [54,55,24,43,26,81,40,40,44,14,47,40,14,17,29,43,27,17,19,8,30,19,32,31,31,32,34,21,30]),
        BibleBook(id: 14, name: "2 Chronicles",   abbreviation: "2Ch",  urlSlug: "2-chronicles",
            versesByChapter: [17,18,17,22,14,42,22,18,31,19,23,16,22,15,19,14,19,34,11,37,20,12,21,27,28,23,9,27,36,27,21,33,25,33,27,23]),
        BibleBook(id: 15, name: "Ezra",            abbreviation: "Ezr",  urlSlug: "ezra",
            versesByChapter: [11,70,13,24,17,22,28,36,15,44]),
        BibleBook(id: 16, name: "Nehemiah",        abbreviation: "Neh",  urlSlug: "nehemiah",
            versesByChapter: [11,20,32,23,19,19,73,18,38,39,36,47,31]),
        BibleBook(id: 17, name: "Esther",          abbreviation: "Est",  urlSlug: "esther",
            versesByChapter: [22,23,15,17,14,14,10,17,32,3]),
        BibleBook(id: 18, name: "Job",             abbreviation: "Job",  urlSlug: "job",
            versesByChapter: [22,13,26,21,27,30,21,22,35,22,20,25,28,22,35,22,16,21,29,29,34,30,17,25,6,14,23,28,25,31,40,22,33,37,16,33,24,41,30,24,34,17]),
        BibleBook(id: 19, name: "Psalms",          abbreviation: "Ps",   urlSlug: "psalms",
            versesByChapter: [6,12,8,8,12,10,17,9,20,18,7,8,6,7,5,11,15,50,14,9,13,31,6,10,22,12,14,9,11,12,24,11,22,22,28,12,40,22,13,17,13,11,5,26,17,11,9,14,20,23,19,9,6,7,23,13,11,11,17,12,8,12,11,10,13,20,7,35,36,5,24,20,28,23,10,12,20,72,13,19,16,8,18,12,13,17,7,18,52,17,16,15,5,23,11,13,12,9,9,5,8,28,22,35,45,48,43,13,31,7,10,10,9,8,18,19,2,29,176,7,8,9,4,8,5,6,5,6,8,8,3,18,3,3,21,26,9,8,24,13,10,7,12,15,21,10,20,14,9,6]),
        BibleBook(id: 20, name: "Proverbs",        abbreviation: "Prov", urlSlug: "proverbs",
            versesByChapter: [33,22,35,27,23,35,27,36,18,32,31,28,25,35,33,33,28,24,29,30,31,29,35,34,28,28,27,28,27,33,31]),
        BibleBook(id: 21, name: "Ecclesiastes",    abbreviation: "Eccl", urlSlug: "ecclesiastes",
            versesByChapter: [18,26,22,16,20,12,29,17,18,20,10,14]),
        BibleBook(id: 22, name: "Song of Solomon", abbreviation: "Song", urlSlug: "song-of-solomon",
            versesByChapter: [17,17,11,16,16,13,13,14]),
        BibleBook(id: 23, name: "Isaiah",          abbreviation: "Isa",  urlSlug: "isaiah",
            versesByChapter: [31,22,26,6,30,13,25,22,21,34,16,6,22,32,9,14,14,7,25,6,17,25,18,23,12,21,13,29,24,33,9,20,24,17,10,22,38,22,8,31,29,25,28,28,25,13,15,22,26,11,23,15,12,17,13,12,21,14,21,22,11,12,19,12,25,24]),
        BibleBook(id: 24, name: "Jeremiah",        abbreviation: "Jer",  urlSlug: "jeremiah",
            versesByChapter: [19,37,25,31,31,30,34,22,26,25,23,17,27,22,21,21,27,23,15,18,14,30,40,10,38,24,22,17,32,24,40,44,26,22,19,32,21,28,18,16,18,22,13,30,5,28,7,47,39,46,64,34]),
        BibleBook(id: 25, name: "Lamentations",   abbreviation: "Lam",  urlSlug: "lamentations",
            versesByChapter: [22,22,66,22,22]),
        BibleBook(id: 26, name: "Ezekiel",         abbreviation: "Ezek", urlSlug: "ezekiel",
            versesByChapter: [28,10,27,17,17,14,27,18,11,22,25,28,23,23,8,63,24,32,14,49,32,31,49,27,17,21,36,26,21,26,18,32,33,31,15,38,28,23,29,49,26,20,27,31,25,24,23,35]),
        BibleBook(id: 27, name: "Daniel",          abbreviation: "Dan",  urlSlug: "daniel",
            versesByChapter: [21,49,30,37,31,28,28,27,27,21,45,13]),
        BibleBook(id: 28, name: "Hosea",           abbreviation: "Hos",  urlSlug: "hosea",
            versesByChapter: [11,23,5,19,15,11,16,14,17,15,12,14,16,9]),
        BibleBook(id: 29, name: "Joel",            abbreviation: "Joel", urlSlug: "joel",
            versesByChapter: [20,32,21]),
        BibleBook(id: 30, name: "Amos",            abbreviation: "Amos", urlSlug: "amos",
            versesByChapter: [15,16,15,13,27,14,17,14,15]),
        BibleBook(id: 31, name: "Obadiah",         abbreviation: "Obad", urlSlug: "obadiah",
            versesByChapter: [21]),
        BibleBook(id: 32, name: "Jonah",           abbreviation: "Jon",  urlSlug: "jonah",
            versesByChapter: [17,10,10,11]),
        BibleBook(id: 33, name: "Micah",           abbreviation: "Mic",  urlSlug: "micah",
            versesByChapter: [16,13,12,13,15,16,20]),
        BibleBook(id: 34, name: "Nahum",           abbreviation: "Nah",  urlSlug: "nahum",
            versesByChapter: [15,13,19]),
        BibleBook(id: 35, name: "Habakkuk",        abbreviation: "Hab",  urlSlug: "habakkuk",
            versesByChapter: [17,20,19]),
        BibleBook(id: 36, name: "Zephaniah",       abbreviation: "Zeph", urlSlug: "zephaniah",
            versesByChapter: [18,15,20]),
        BibleBook(id: 37, name: "Haggai",          abbreviation: "Hag",  urlSlug: "haggai",
            versesByChapter: [15,23]),
        BibleBook(id: 38, name: "Zechariah",       abbreviation: "Zech", urlSlug: "zechariah",
            versesByChapter: [21,13,10,14,11,15,14,23,17,12,17,14,9,21]),
        BibleBook(id: 39, name: "Malachi",         abbreviation: "Mal",  urlSlug: "malachi",
            versesByChapter: [14,17,18,6]),

        // ── New Testament ──────────────────────────────────────────────
        BibleBook(id: 40, name: "Matthew",         abbreviation: "Matt", urlSlug: "matthew",
            versesByChapter: [25,23,17,25,48,34,29,34,38,42,30,50,58,36,39,28,27,35,30,34,46,46,39,51,46,75,66,20]),
        BibleBook(id: 41, name: "Mark",            abbreviation: "Mark", urlSlug: "mark",
            versesByChapter: [45,28,35,41,43,56,37,38,50,52,33,44,37,72,47,20]),
        BibleBook(id: 42, name: "Luke",            abbreviation: "Luke", urlSlug: "luke",
            versesByChapter: [80,52,38,44,39,49,50,56,62,42,54,59,35,35,32,31,37,43,48,47,38,71,56,53]),
        BibleBook(id: 43, name: "John",            abbreviation: "John", urlSlug: "john",
            versesByChapter: [51,25,36,54,47,71,53,59,41,42,57,50,38,31,27,33,26,40,42,31,25]),
        BibleBook(id: 44, name: "Acts",            abbreviation: "Acts", urlSlug: "acts",
            versesByChapter: [26,47,26,37,42,15,60,40,43,48,30,25,52,28,41,40,34,28,41,38,40,30,35,27,27,32,44,31]),
        BibleBook(id: 45, name: "Romans",          abbreviation: "Rom",  urlSlug: "romans",
            versesByChapter: [32,29,31,25,21,23,25,39,33,21,36,21,14,23,33,27]),
        BibleBook(id: 46, name: "1 Corinthians",   abbreviation: "1Co",  urlSlug: "1-corinthians",
            versesByChapter: [31,16,23,21,13,20,40,13,27,33,34,31,13,40,58,24]),
        BibleBook(id: 47, name: "2 Corinthians",   abbreviation: "2Co",  urlSlug: "2-corinthians",
            versesByChapter: [24,17,18,18,21,18,16,24,15,18,33,21,14]),
        BibleBook(id: 48, name: "Galatians",       abbreviation: "Gal",  urlSlug: "galatians",
            versesByChapter: [24,21,29,31,26,18]),
        BibleBook(id: 49, name: "Ephesians",       abbreviation: "Eph",  urlSlug: "ephesians",
            versesByChapter: [23,22,21,32,33,24]),
        BibleBook(id: 50, name: "Philippians",     abbreviation: "Phil", urlSlug: "philippians",
            versesByChapter: [30,30,21,23]),
        BibleBook(id: 51, name: "Colossians",      abbreviation: "Col",  urlSlug: "colossians",
            versesByChapter: [29,23,25,18]),
        BibleBook(id: 52, name: "1 Thessalonians", abbreviation: "1Th",  urlSlug: "1-thessalonians",
            versesByChapter: [10,20,13,18,28]),
        BibleBook(id: 53, name: "2 Thessalonians", abbreviation: "2Th",  urlSlug: "2-thessalonians",
            versesByChapter: [12,17,18]),
        BibleBook(id: 54, name: "1 Timothy",       abbreviation: "1Ti",  urlSlug: "1-timothy",
            versesByChapter: [20,15,16,16,25,21]),
        BibleBook(id: 55, name: "2 Timothy",       abbreviation: "2Ti",  urlSlug: "2-timothy",
            versesByChapter: [18,26,17,22]),
        BibleBook(id: 56, name: "Titus",           abbreviation: "Tit",  urlSlug: "titus",
            versesByChapter: [16,15,15]),
        BibleBook(id: 57, name: "Philemon",        abbreviation: "Phm",  urlSlug: "philemon",
            versesByChapter: [25]),
        BibleBook(id: 58, name: "Hebrews",         abbreviation: "Heb",  urlSlug: "hebrews",
            versesByChapter: [14,18,19,16,14,20,28,13,28,39,40,29,25]),
        BibleBook(id: 59, name: "James",           abbreviation: "Jas",  urlSlug: "james",
            versesByChapter: [27,26,18,17,20]),
        BibleBook(id: 60, name: "1 Peter",         abbreviation: "1Pe",  urlSlug: "1-peter",
            versesByChapter: [25,25,22,19,14]),
        BibleBook(id: 61, name: "2 Peter",         abbreviation: "2Pe",  urlSlug: "2-peter",
            versesByChapter: [21,22,18]),
        BibleBook(id: 62, name: "1 John",          abbreviation: "1Jo",  urlSlug: "1-john",
            versesByChapter: [10,29,24,21,21]),
        BibleBook(id: 63, name: "2 John",          abbreviation: "2Jo",  urlSlug: "2-john",
            versesByChapter: [13]),
        BibleBook(id: 64, name: "3 John",          abbreviation: "3Jo",  urlSlug: "3-john",
            versesByChapter: [14]),
        BibleBook(id: 65, name: "Jude",            abbreviation: "Jude", urlSlug: "jude",
            versesByChapter: [25]),
        BibleBook(id: 66, name: "Revelation",      abbreviation: "Rev",  urlSlug: "revelation",
            versesByChapter: [20,29,22,11,14,17,17,13,21,11,19,17,18,20,8,21,18,24,21,15,27,21]),
    ]

    // MARK: - Convenience lookups

    static func book(id: Int) -> BibleBook? {
        books.first { $0.id == id }
    }

    static func book(named name: String) -> BibleBook? {
        books.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Attempt to detect which BibleBook matches a jw.org URL.
    static func book(fromURL url: URL) -> BibleBook? {
        let path = url.absoluteString
        return books.first { path.contains("/\($0.urlSlug)/") }
    }

    /// Parse chapter from URL path segment after the book slug.
    static func chapter(fromURL url: URL) -> Int? {
        guard let book = book(fromURL: url) else { return nil }
        let str = url.absoluteString
        guard let range = str.range(of: "/\(book.urlSlug)/") else { return nil }
        let after = String(str[range.upperBound...])
        let segment = after.components(separatedBy: "/").first ?? ""
        return Int(segment)
    }
}
