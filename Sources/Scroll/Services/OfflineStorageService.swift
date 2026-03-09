import Foundation
import WebKit
import SwiftData

// MARK: - OfflineStorageService

@MainActor
final class OfflineStorageService {
    static let shared = OfflineStorageService()

    /// Maximum total storage for saved pages (500 MB)
    static let maxBytes: Int64 = 500 * 1_048_576

    // MARK: Paths

    var storageDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("OfflinePages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func fileURL(for page: OfflinePage) -> URL {
        storageDirectory.appendingPathComponent(page.filePath)
    }

    // MARK: Queries

    func savedPage(url: String, context: ModelContext) -> OfflinePage? {
        var desc = FetchDescriptor<OfflinePage>(
            predicate: #Predicate { $0.url == url }
        )
        desc.fetchLimit = 1
        return (try? context.fetch(desc))?.first
    }

    func isSaved(url: String, context: ModelContext) -> Bool {
        savedPage(url: url, context: context) != nil
    }

    /// Returns the local file URL if the page is saved and the archive file exists,
    /// updating the last-accessed date for LRU tracking.
    func localFileURL(url: String, context: ModelContext) -> URL? {
        guard let page = savedPage(url: url, context: context) else { return nil }
        let furl = fileURL(for: page)
        guard FileManager.default.fileExists(atPath: furl.path) else { return nil }
        page.lastAccessedDate = Date()
        try? context.save()
        return furl
    }

    func totalUsed(context: ModelContext) -> Int64 {
        let desc = FetchDescriptor<OfflinePage>()
        return ((try? context.fetch(desc)) ?? []).reduce(0) { $0 + $1.fileSize }
    }

    // MARK: Save

    func save(
        webView: WKWebView,
        url: String,
        title: String,
        context: ModelContext
    ) async throws {
        let data = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
            webView.createWebArchiveData { result in
                switch result {
                case .success(let d): cont.resume(returning: d)
                case .failure(let e): cont.resume(throwing: e)
                }
            }
        }

        // Remove any existing entry for this URL first
        if let existing = savedPage(url: url, context: context) {
            remove(page: existing, context: context)
        }

        let page = OfflinePage(url: url, title: title, fileSize: Int64(data.count))
        try data.write(to: fileURL(for: page))
        context.insert(page)
        try context.save()

        pruneIfNeeded(context: context)
    }

    // MARK: Remove

    func remove(page: OfflinePage, context: ModelContext) {
        try? FileManager.default.removeItem(at: fileURL(for: page))
        context.delete(page)
        try? context.save()
    }

    // MARK: Load offline version into a WKWebView

    func loadOfflinePage(url: String, into webView: WKWebView, context: ModelContext) {
        guard let fileURL = localFileURL(url: url, context: context) else { return }
#if os(iOS)
        if let data = try? Data(contentsOf: fileURL) {
            let baseURL = URL(string: url) ?? fileURL
            webView.load(data, mimeType: "application/x-webarchive",
                         characterEncodingName: "utf-8", baseURL: baseURL)
        }
#else
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
#endif
    }

    // MARK: Auto-pruning (LRU – evicts least-recently-accessed first)

    private func pruneIfNeeded(context: ModelContext) {
        let desc = FetchDescriptor<OfflinePage>(
            sortBy: [SortDescriptor(\.lastAccessedDate, order: .forward)]
        )
        guard let pages = try? context.fetch(desc) else { return }
        var total = pages.reduce(0) { $0 + $1.fileSize }
        guard total > Self.maxBytes else { return }
        for page in pages {
            guard total > Self.maxBytes else { break }
            total -= page.fileSize
            remove(page: page, context: context)
        }
    }
}
