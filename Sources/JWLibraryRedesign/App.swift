import SwiftUI
import SwiftData

// MARK: - App entry point

@main
struct JWLibraryApp: App {

    @StateObject private var tabManager = TabManager()

    // MARK: SwiftData schema
    private static let schema = Schema([
        Note.self,
        Highlight.self,
        Playlist.self,
        PlaylistItem.self,
        BrowsingHistoryEntry.self,
    ])

    private static let modelConfig = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )

    @State private var modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: modelConfig)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scenes

    var body: some Scene {
#if os(macOS)
        macScene
#else
        iosScene
#endif
    }

    // MARK: - iOS scene

    private var iosScene: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabManager)
                .environment(tabManager)
                .modelContainer(modelContainer)
        }
    }

    // MARK: - macOS scene

    private var macScene: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(tabManager)
                .environment(tabManager)
                .modelContainer(modelContainer)
                .frame(minWidth: 1100, minHeight: 750)
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    tabManager.newTab()
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button("Close Tab") {
                    if let tab = tabManager.activeTab {
                        tabManager.closeTab(tab)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }
        }
    }
}
