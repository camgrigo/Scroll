import SwiftUI
import SwiftData

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.modelContext) private var modelContext

    // Shared across all tabs – persists across tab switches
    @State private var webViewStore = WebViewStore()

    // Reader toolbar state (passed down to NavigationToolbarView)
    @State private var isPageSaved = false
    @State private var isSaving    = false
    @State private var showPageNoteEditor = false

    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    private var sidebarOpen: Bool { columnVisibility != .detailOnly }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {

            // ── SIDEBAR: Personal Study ───────────────────────────────
            PersonalStudyView()
                .navigationTitle("Personal Study")
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 400)
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#endif

        } detail: {

            // ── DETAIL: Browser ───────────────────────────────────────
            VStack(spacing: 0) {

                // Tab strip
                TabBarView()
                    .frame(height: AppTheme.tabBarHeight)

                // Navigation toolbar
                NavigationToolbarView(
                    sidebarOpen:     sidebarOpen,
                    onToggleSidebar: toggleSidebar,
                    webViewStore:    webViewStore,
                    isPageSaved:     $isPageSaved,
                    isSaving:        $isSaving,
                    showPageNote:    $showPageNoteEditor
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
                            WebReaderView(tab: tab, webViewStore: webViewStore)
                                .transition(.opacity)
                                .id(tab.id)
                                .onChange(of: tab.currentURL) { _, newURL in
                                    guard let url = newURL else { return }
                                    addHistoryEntry(for: tab, url: url)
                                    // Check offline status for new URL
                                    updateOfflineStatus(url: url.absoluteString)
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
        .onChange(of: tabManager.activeTabID) { _, _ in
            if let url = tabManager.activeTab?.currentURL?.absoluteString {
                updateOfflineStatus(url: url)
            } else {
                isPageSaved = false
            }
        }
        // Page-level note sheet
        .sheet(isPresented: $showPageNoteEditor) {
            let note = Note(
                publicationURL: tabManager.activeTab?.currentURL?.absoluteString
            )
            NoteEditorView(note: note, isNew: true)
        }
    }

    // MARK: - Helpers

    private func toggleSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            columnVisibility = sidebarOpen ? .detailOnly : .all
        }
    }

    private func updateOfflineStatus(url: String) {
        isPageSaved = OfflineStorageService.shared.isSaved(url: url, context: modelContext)
    }

    private func addHistoryEntry(for tab: TabItem, url: URL) {
        let urlString  = url.absoluteString
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
    @Environment(\.modelContext) private var modelContext

    let sidebarOpen:     Bool
    let onToggleSidebar: () -> Void
    let webViewStore:    WebViewStore

    @Binding var isPageSaved: Bool
    @Binding var isSaving:    Bool
    @Binding var showPageNote: Bool

    private var activeTab: TabItem? { tabManager.activeTab }

    var body: some View {
        HStack(spacing: 0) {

            // ── Sidebar toggle ─────────────────────────────────────
            Button(action: onToggleSidebar) {
                Image(systemName: "sidebar.left")
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

            toolbarSep()

            // ── Back ───────────────────────────────────────────────
            Button { navigateBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(activeTab?.canGoBack == true
                        ? AppTheme.text
                        : AppTheme.textSecondary.opacity(0.35))
                    .frame(width: 40, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(activeTab?.canGoBack != true)

            // ── Forward ────────────────────────────────────────────
            Button { navigateForward() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(activeTab?.canGoForward == true
                        ? AppTheme.text
                        : AppTheme.textSecondary.opacity(0.35))
                    .frame(width: 40, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(activeTab?.canGoForward != true)

            Spacer()

            // ── Page title ─────────────────────────────────────────
            Text(activeTab?.title ?? "New Tab")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 200)

            Spacer()

            // ── Right-side action buttons ──────────────────────────

            // Add note for this page
            if activeTab?.currentURL != nil {
                Button { showPageNote = true } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 44)
                }
                .buttonStyle(.plain)
                .help("Add note for this page")
            }

            // Reader mode toggle
            if activeTab?.currentURL != nil {
                Button {
                    activeTab?.isReaderMode.toggle()
                } label: {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14,
                                      weight: activeTab?.isReaderMode == true ? .semibold : .regular))
                        .foregroundStyle(activeTab?.isReaderMode == true
                            ? AppTheme.accent
                            : AppTheme.textSecondary)
                        .frame(width: 36, height: 44)
                        .background(
                            activeTab?.isReaderMode == true
                                ? AnyShapeStyle(AppTheme.accent.opacity(0.12))
                                : AnyShapeStyle(Color.clear),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
                .help(activeTab?.isReaderMode == true ? "Exit Reader Mode" : "Reader Mode")
            }

            // Offline save / load
            if activeTab?.currentURL != nil {
                Button { toggleOffline() } label: {
                    Group {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(AppTheme.accent)
                        } else {
                            Image(systemName: isPageSaved ? "checkmark.icloud.fill" : "icloud.and.arrow.down")
                                .font(.system(size: 14,
                                              weight: isPageSaved ? .semibold : .regular))
                                .foregroundStyle(isPageSaved ? AppTheme.accent : AppTheme.textSecondary)
                        }
                    }
                    .frame(width: 36, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .help(isPageSaved ? "Remove offline copy" : "Save for offline reading")
            }

            toolbarSep()

            // ── Bible scrubber ─────────────────────────────────────
            BibleScrubberButton()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions

    private func navigateBack()    { NotificationCenter.default.post(name: .webViewGoBack,    object: tabManager.activeTabID) }
    private func navigateForward() { NotificationCenter.default.post(name: .webViewGoForward, object: tabManager.activeTabID) }

    private func toggleOffline() {
        guard let tab  = activeTab,
              let url  = tab.currentURL?.absoluteString,
              let tabID = tabManager.activeTabID else { return }

        if isPageSaved {
            // Remove
            if let page = OfflineStorageService.shared.savedPage(url: url, context: modelContext) {
                OfflineStorageService.shared.remove(page: page, context: modelContext)
                isPageSaved = false
            }
        } else {
            // Save
            guard let wv = webViewStore.webViews[tabID] else { return }
            isSaving = true
            Task {
                try? await OfflineStorageService.shared.save(
                    webView: wv,
                    url: url,
                    title: tab.title,
                    context: modelContext
                )
                await MainActor.run {
                    isSaving    = false
                    isPageSaved = true
                }
            }
        }
    }

    private func toolbarSep() -> some View {
        Rectangle()
            .fill(AppTheme.textSecondary.opacity(0.2))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 2)
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
                Rectangle().fill(AppTheme.accent.opacity(0.2))
                Rectangle()
                    .fill(AppTheme.accent)
                    .frame(width: geo.size.width * 0.35)
                    .offset(x: animating ? geo.size.width : -geo.size.width * 0.35)
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false),
                               value: animating)
            }
        }
        .onAppear   { animating = true }
        .onDisappear { animating = false }
        .clipped()
    }
}
