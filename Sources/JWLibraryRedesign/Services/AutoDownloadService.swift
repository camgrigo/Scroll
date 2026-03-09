import Foundation
import SwiftUI

// MARK: - AutoDownloadService

final class AutoDownloadService: ObservableObject {

    @AppStorage("autoDownloadEnabled")          var enabled: Bool = false
    @AppStorage("autoDownloadOnWifiOnly")       var wifiOnly: Bool = true
    @AppStorage("autoDownloadMeetingMaterials") var downloadMeetingMaterials: Bool = true
    @AppStorage("autoDownloadWatchtower")       var downloadWatchtower: Bool = true

    // MARK: - Schedule

    /// Schedules a weekly background download task.
    /// On platforms where BackgroundTasks is available this registers a task identifier.
    func scheduleWeeklyDownload() {
        // BackgroundTasks is iOS/macOS specific and requires plist configuration.
        // Here we set a UserDefaults marker so the app can check on next launch.
        let nextDownload = nextMondayMorning()
        UserDefaults.standard.set(nextDownload, forKey: "nextScheduledDownload")
    }

    // MARK: - Download

    @MainActor
    func downloadCurrentWeekMaterials() async {
        guard enabled else { return }

        let materials = MeetingMaterialsService.thisWeekMaterials()
        var urlsToDownload: [URL] = []

        if downloadMeetingMaterials { urlsToDownload.append(materials.workbook) }
        if downloadWatchtower       { urlsToDownload.append(materials.watchtower) }

        for url in urlsToDownload {
            await prefetchURL(url)
        }
    }

    // MARK: - Private

    @MainActor
    private func prefetchURL(_ url: URL) async {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            // Silently handle — background prefetch is best-effort
        }
    }

    private func nextMondayMorning() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard var monday = cal.date(from: comps) else { return Date() }
        monday = cal.date(byAdding: .weekOfYear, value: 1, to: monday) ?? monday
        var time = DateComponents()
        time.hour = 5; time.minute = 0
        return cal.nextDate(after: monday, matching: time, matchingPolicy: .nextTime) ?? monday
    }
}
