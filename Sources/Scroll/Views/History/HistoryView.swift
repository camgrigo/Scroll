import SwiftUI
import SwiftData

// MARK: - HistoryView

struct HistoryView: View {
    @Query(sort: \BrowsingHistoryEntry.visitedAt, order: .reverse) var entries: [BrowsingHistoryEntry]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabManager: TabManager

    @State private var searchText = ""
    @State private var showClearConfirm = false

    // MARK: - Filtering

    private var filtered: [BrowsingHistoryEntry] {
        if searchText.isEmpty { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.url.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Grouping

    private var grouped: [(key: String, entries: [BrowsingHistoryEntry])] {
        let dict = Dictionary(grouping: filtered) { entry -> String in
            sectionTitle(for: entry.visitedAt)
        }
        let order = ["Today", "Yesterday", "This Week", "Older"]
        return order.compactMap { key -> (String, [BrowsingHistoryEntry])? in
            guard let es = dict[key], !es.isEmpty else { return nil }
            return (key, es)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(grouped, id: \.key) { group in
                            Section(header: sectionHeader(group.key)) {
                                ForEach(group.entries) { entry in
                                    HistoryRow(entry: entry)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if let url = URL(string: entry.url) {
                                                tabManager.navigateActiveTab(to: url, title: entry.title)
                                                dismiss()
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                modelContext.delete(entry)
                                                try? modelContext.save()
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("History")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .searchable(text: $searchText, prompt: "Search history…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    if !entries.isEmpty {
                        Button {
                            showClearConfirm = true
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Clear all browsing history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) { clearAllHistory() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary)
            Text("No History")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
            Text("Pages you visit will appear here.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.uppercaseSmallCaps())
            .foregroundStyle(AppTheme.textSecondary)
    }

    // MARK: - Helpers

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if let interval = cal.dateInterval(of: .weekOfYear, for: Date()), interval.contains(date) {
            return "This Week"
        }
        return "Older"
    }

    private func clearAllHistory() {
        for entry in entries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - HistoryRow

struct HistoryRow: View {
    let entry: BrowsingHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            // Favicon
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 36, height: 36)
                Image(systemName: entry.faviconSystemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.accent)
            }

            // Titles
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                Text(entry.url)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Time
            Text(entry.visitedAt, style: .time)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, 4)
        .listRowBackground(AppTheme.surface.opacity(0.6))
    }
}
