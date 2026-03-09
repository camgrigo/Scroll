import SwiftUI
import SwiftData

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    // iOS 26 NavigationSplitView column visibility
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    private var sidebarOpen: Bool { columnVisibility != .detailOnly }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {

            // ── SIDEBAR: Personal Study ───────────────────────────────
            PersonalStudyView()
                .navigationTitle("Personal Study")
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 400)
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)   // we use our own header
#endif

        } detail: {

            // ── DETAIL: Browser ───────────────────────────────────────
            VStack(spacing: 0) {

                // Tab strip
                TabBarView()
                    .frame(height: AppTheme.tabBarHeight)

                // Navigation toolbar
                NavigationToolbarView(
                    sidebarOpen:    sidebarOpen,
                    onToggleSidebar: toggleSidebar
                )
                .frame(height: 44)
                .background(AppTheme.surface.opacity(0.95))

                Divider()
                    .background(AppTheme.textSecondary.opacity(0.2))

                // Loading indicator
                if tabManager.activeTab?.isLoading == true {
                    IndeterminateProgressBar()
                        .frame(height: 2)
                }

                // Content area
                ZStack {
                    AppTheme.background.ignoresSafeArea()

                    if let tab = tabManager.activeTab {
                        if tab.currentURL == nil {
                            NewTabView()
                                .transition(.opacity)
                        } else {
                            WebReaderView(tab: tab)
                                .transition(.opacity)
                                .id(tab.id)
                                .onChange(of: tab.currentURL) { _, newURL in
                                    guard let url = newURL else { return }
                                    addHistoryEntry(for: tab, url: url)
                                }
                        }
                    } else {
                        NewTabView()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: tabManager.activeTabID)
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(.dark)
    }

    // MARK: - Sidebar toggle

    private func toggleSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            columnVisibility = sidebarOpen ? .detailOnly : .all
        }
    }

    // MARK: - History deduplication

    private func addHistoryEntry(for tab: TabItem, url: URL) {
        let urlString = url.absoluteString
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<BrowsingHistoryEntry>(
            predicate: #Predicate { $0.url == urlString && $0.visitedAt >= startOfDay }
        )
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty { return }
        let entry = BrowsingHistoryEntry(
            title: tab.title,
            url: urlString,
            faviconSystemImage: tab.faviconSystemImage
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }
}

// MARK: - NavigationToolbarView

struct NavigationToolbarView: View {
    @EnvironmentObject var tabManager: TabManager
    let sidebarOpen:     Bool
    let onToggleSidebar: () -> Void

    private var activeTab: TabItem? { tabManager.activeTab }

    var body: some View {
        HStack(spacing: 0) {

            // ── Sidebar toggle ───────────────────────────────────────
            Button(action: onToggleSidebar) {
                Image(systemName: sidebarOpen ? "sidebar.left" : "sidebar.left")
                    .font(.system(size: 16, weight: sidebarOpen ? .semibold : .regular))
                    .foregroundStyle(sidebarOpen ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 40, height: 44)
                    .background(
                        sidebarOpen
                            ? AnyShapeStyle(AppTheme.accent.opacity(0.12))
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
            .buttonStyle(.plain)
            .help("Toggle Personal Study")

            // Thin separator
            Rectangle()
                .fill(AppTheme.textSecondary.opacity(0.2))
                .frame(width: 1, height: 20)
                .padding(.horizontal, 2)

            // ── Back ─────────────────────────────────────────────────
            Button { navigateBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        activeTab?.canGoBack == true
                            ? AppTheme.text
                            : AppTheme.textSecondary.opacity(0.35)
                    )
                    .frame(width: 40, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(activeTab?.canGoBack != true)

            // ── Forward ───────────────────────────────────────────────
            Button { navigateForward() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        activeTab?.canGoForward == true
                            ? AppTheme.text
                            : AppTheme.textSecondary.opacity(0.35)
                    )
                    .frame(width: 40, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(activeTab?.canGoForward != true)

            Spacer()

            // ── Page title ────────────────────────────────────────────
            Text(activeTab?.title ?? "New Tab")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 220)

            Spacer()

            // ── Bible scrubber (only on Bible pages) ─────────────────
            BibleScrubberButton()
        }
        .padding(.horizontal, 4)
    }

    private func navigateBack() {
        NotificationCenter.default.post(name: .webViewGoBack, object: tabManager.activeTabID)
    }
    private func navigateForward() {
        NotificationCenter.default.post(name: .webViewGoForward, object: tabManager.activeTabID)
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let webViewGoBack    = Notification.Name("webViewGoBack")
    static let webViewGoForward = Notification.Name("webViewGoForward")
}

// MARK: - Indeterminate progress bar

struct IndeterminateProgressBar: View {
    @State private var animating = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.accent.opacity(0.2))
                Rectangle()
                    .fill(AppTheme.accent)
                    .frame(width: geo.size.width * 0.35)
                    .offset(x: animating ? geo.size.width : -geo.size.width * 0.35)
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: animating
                    )
            }
        }
        .onAppear  { animating = true }
        .onDisappear { animating = false }
        .clipped()
    }
}
