import Foundation
import SwiftUI
import Observation

// MARK: - TabManager

@Observable
final class TabManager: ObservableObject {

    // MARK: - State

    var tabs: [TabItem] = []
    var activeTabID: UUID?

    // MARK: - Computed

    var activeTab: TabItem? { tabs.first { $0.id == activeTabID } }

    // MARK: - Settings

    // @AppStorage is incompatible with @Observable; use UserDefaults directly.
    @ObservationIgnored private let autoCloseKey = "autoCloseTabsEnabled"
    var autoCloseEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoCloseKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoCloseKey) }
    }

    // MARK: - Init

    init() {
        loadTabs()

        // Set active tab (ensure something is selected)
        if activeTabID == nil || tabs.first(where: { $0.id == activeTabID }) == nil {
            if tabs.isEmpty { _ = newTab() }
            activeTabID = tabs.first?.id
        }

        if autoCloseEnabled { pruneExpiredTabs() }
    }

    // MARK: - Tab operations

    @discardableResult
    func newTab(url: URL? = nil, title: String = "New Tab") -> TabItem {
        let tab = TabItem(title: title, currentURL: url)
        tabs.append(tab)
        activeTabID = tab.id
        saveTabs()
        return tab
    }

    func closeTab(_ tab: TabItem) {
        if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: idx)
        }
        // Select a neighbouring tab
        if activeTabID == tab.id {
            activeTabID = tabs.last?.id
        }
        saveTabs()
    }

    func selectTab(_ tab: TabItem) {
        activeTabID = tab.id
        tab.lastAccessedAt = Date()
        saveTabs()
    }

    func navigateActiveTab(to url: URL, title: String) {
        if let tab = activeTab {
            tab.currentURL = url
            tab.title = title
            tab.lastAccessedAt = Date()
            saveTabs()
        } else {
            newTab(url: url, title: title)
        }
    }

    func openInNewTab(url: URL, title: String) {
        newTab(url: url, title: title)
    }

    // MARK: - Persistence

    func saveTabs() {
        do {
            let data = try JSONEncoder().encode(tabs)
            UserDefaults.standard.set(data, forKey: "saved_tabs")
        } catch {
            print("TabManager: save error \(error)")
        }
    }

    func loadTabs() {
        guard let data = UserDefaults.standard.data(forKey: "saved_tabs") else { return }
        do {
            tabs = try JSONDecoder().decode([TabItem].self, from: data)
            .filter { !$0.isPersonalStudy }   // PS is now a sidebar, not a tab
            // Restore last active tab id
            if let idString = UserDefaults.standard.string(forKey: "active_tab_id"),
               let id = UUID(uuidString: idString) {
                activeTabID = id
            }
        } catch {
            print("TabManager: load error \(error)")
            tabs = []
        }
    }

    // MARK: - Auto-close

    func pruneExpiredTabs() {
        let cutoff = Date().addingTimeInterval(-86_400)  // 1 day
        tabs.removeAll { !$0.isPersonalStudy && $0.lastAccessedAt < cutoff }
        saveTabs()
    }
}
