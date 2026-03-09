import SwiftUI
import SwiftData

// MARK: - NewTabView

struct NewTabView: View {
    @EnvironmentObject var tabManager: TabManager

    @Query(sort: \BrowsingHistoryEntry.visitedAt, order: .reverse)
    private var recentHistory: [BrowsingHistoryEntry]

    private var adaptiveColumns: [GridItem] {
#if os(macOS)
        [GridItem(.adaptive(minimum: 160, maximum: 220))]
#else
        [GridItem(.adaptive(minimum: 140))]
#endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("What would you like to read?")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text)
                    Text(greetingText())
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // MARK: Destination grid
                LazyVGrid(columns: adaptiveColumns, spacing: 14) {
                    ForEach(JWDestination.allCases) { dest in
                        DestinationCard(destination: dest) {
                            tabManager.navigateActiveTab(to: dest.url, title: dest.title)
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: Quick history access
                if !recentHistory.isEmpty {
                    HistoryQuickAccessRow(entries: Array(recentHistory.prefix(8)))
                }

                Spacer(minLength: 40)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }
}

// MARK: - HistoryQuickAccessRow

struct HistoryQuickAccessRow: View {
    let entries: [BrowsingHistoryEntry]
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(entries) { entry in
                        recentChip(entry)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func recentChip(_ entry: BrowsingHistoryEntry) -> some View {
        Button {
            if let url = URL(string: entry.url) {
                tabManager.navigateActiveTab(to: url, title: entry.title)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: entry.faviconSystemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.accent)
                Text(entry.title)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(AppTheme.surface)
            )
        }
        .buttonStyle(.plain)
    }
}
