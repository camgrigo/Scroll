import SwiftUI

// MARK: - BibleScrubberView
//
// A three-column wheel scrubber (Book | Chapter | Verse) that navigates
// directly to any scripture on jw.org. Presented as a popover from the
// navigation toolbar whenever a Bible page is active.

struct BibleScrubberView: View {
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedBookIndex: Int = 0
    @State private var selectedChapter:   Int = 1
    @State private var selectedVerse:     Int = 1

    private var selectedBook: BibleBook { BibleData.books[selectedBookIndex] }
    private var maxChapter:   Int { selectedBook.chapterCount }
    private var maxVerse:     Int { selectedBook.verseCount(forChapter: selectedChapter) }

    // MARK: - Init (pre-select from current tab URL if possible)

    init() { }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(AppTheme.textSecondary.opacity(0.2))
            pickerSection
            Divider().background(AppTheme.textSecondary.opacity(0.2))
            footerButtons
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .onAppear(perform: preselectFromCurrentURL)
        // Clamp chapter / verse when book changes
        .onChange(of: selectedBookIndex) { _, _ in
            selectedChapter = min(selectedChapter, maxChapter)
            selectedVerse   = min(selectedVerse, maxVerse)
        }
        .onChange(of: selectedChapter) { _, _ in
            selectedVerse = min(selectedVerse, maxVerse)
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack {
            Image(systemName: "book.fill")
                .foregroundStyle(AppTheme.accent)
            Text("Go to Scripture")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var pickerSection: some View {
#if os(iOS)
        wheelPickerSection
#else
        macPickerSection
#endif
    }

    // Wheel-style for iOS
#if os(iOS)
    private var wheelPickerSection: some View {
        HStack(spacing: 0) {
            Picker("Book", selection: $selectedBookIndex) {
                ForEach(BibleData.books.indices, id: \.self) { i in
                    Text(BibleData.books[i].name).tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 150)
            .clipped()

            columnDivider

            Picker("Chapter", selection: $selectedChapter) {
                ForEach(1...maxChapter, id: \.self) { ch in Text("\(ch)").tag(ch) }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)
            .clipped()
            .id("ch-\(selectedBookIndex)")

            columnDivider

            Picker("Verse", selection: $selectedVerse) {
                ForEach(1...maxVerse, id: \.self) { v in Text("\(v)").tag(v) }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)
            .clipped()
            .id("v-\(selectedBookIndex)-\(selectedChapter)")
        }
        .frame(height: 180)
        .overlay(alignment: .top) {
            HStack(spacing: 0) {
                columnLabel("Book",    minWidth: 150)
                columnLabel("Chapter", width: 70)
                columnLabel("Verse",   width: 70)
            }
            .padding(.top, 4)
        }
    }
#endif

    // Menu-style for macOS
    private var macPickerSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                columnLabel("Book", minWidth: 0)
                Picker("Book", selection: $selectedBookIndex) {
                    ForEach(BibleData.books.indices, id: \.self) { i in
                        Text(BibleData.books[i].name).tag(i)
                    }
                }
                .frame(minWidth: 160)
            }

            VStack(alignment: .leading, spacing: 6) {
                columnLabel("Chapter", minWidth: 0)
                Picker("Chapter", selection: $selectedChapter) {
                    ForEach(1...maxChapter, id: \.self) { ch in Text("\(ch)").tag(ch) }
                }
                .frame(width: 80)
                .id("ch-\(selectedBookIndex)")
            }

            VStack(alignment: .leading, spacing: 6) {
                columnLabel("Verse", minWidth: 0)
                Picker("Verse", selection: $selectedVerse) {
                    ForEach(1...maxVerse, id: \.self) { v in Text("\(v)").tag(v) }
                }
                .frame(width: 80)
                .id("v-\(selectedBookIndex)-\(selectedChapter)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var columnDivider: some View {
        Divider()
            .frame(width: 1)
            .background(AppTheme.textSecondary.opacity(0.15))
    }

    private func columnLabel(_ text: String, minWidth: CGFloat? = nil, width: CGFloat? = nil) -> some View {
        Group {
            if let w = width {
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: w)
            } else if let min = minWidth {
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(minWidth: min)
            }
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 12) {
            // Reference label
            Text(referenceString)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Open in new tab
            Button {
                openInNewTab()
            } label: {
                Label("New Tab", systemImage: "plus.square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)

            // Navigate in current tab
            Button {
                navigate()
            } label: {
                Text("Go")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var referenceString: String {
        "\(selectedBook.name) \(selectedChapter):\(selectedVerse)"
    }

    private func navigate() {
        let url = selectedBook.jwOrgURL(chapter: selectedChapter, verse: selectedVerse)
        tabManager.navigateActiveTab(to: url, title: referenceString)
        dismiss()
    }

    private func openInNewTab() {
        let url = selectedBook.jwOrgURL(chapter: selectedChapter, verse: selectedVerse)
        tabManager.openInNewTab(url: url, title: referenceString)
        dismiss()
    }

    /// Pre-select pickers to match the currently loaded Bible page.
    private func preselectFromCurrentURL() {
        guard let url = tabManager.activeTab?.currentURL else { return }
        if let book = BibleData.book(fromURL: url),
           let bookIndex = BibleData.books.firstIndex(where: { $0.id == book.id }) {
            selectedBookIndex = bookIndex
            if let ch = BibleData.chapter(fromURL: url) {
                selectedChapter = max(1, min(ch, book.chapterCount))
            }
        }
    }
}

// MARK: - BibleScrubberButton
//
// A toolbar button that shows the scrubber popover. Visible only when
// the active tab is on a jw.org Bible page.

struct BibleScrubberButton: View {
    @EnvironmentObject var tabManager: TabManager

    @State private var showScrubber = false

    private var isBiblePage: Bool {
        tabManager.activeTab?.currentURL?
            .absoluteString.contains("/library/bible/") == true
    }

    var body: some View {
        if isBiblePage {
            Button {
                showScrubber.toggle()
            } label: {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showScrubber, arrowEdge: .top) {
                BibleScrubberView()
                    .environmentObject(tabManager)
                    .frame(width: 340)
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.25), value: isBiblePage)
        }
    }
}
