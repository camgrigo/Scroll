import SwiftUI

// MARK: - PersonalStudyView

struct PersonalStudyView: View {
    @EnvironmentObject var tabManager: TabManager
    @State private var selectedSection: StudySection = .links

    enum StudySection: String, CaseIterable {
        case links     = "Links"
        case notes     = "Notes"
        case playlists = "Playlists"
        case history   = "History"
        case settings  = "Settings"

        var systemImage: String {
            switch self {
            case .links:     return "link"
            case .notes:     return "note.text"
            case .playlists: return "music.note.list"
            case .history:   return "clock"
            case .settings:  return "gearshape"
            }
        }
    }

    // Web links from JW Library home page
    private struct WebLink: Identifiable {
        let title: String
        let url: String
        let icon: String
        let tileColor: Color
        let iconColor: Color
        var id: String { url }
    }

    private let webLinks: [WebLink] = [
        WebLink(title: "Official Website", url: "https://www.jw.org",                            icon: "globe",                 tileColor: Color(hex: "#4A6FA5"), iconColor: .white),
        WebLink(title: "Broadcasting",     url: "https://tv.jw.org",                             icon: "play.rectangle.fill",   tileColor: Color(hex: "#8A8A8E"), iconColor: .white),
        WebLink(title: "Online Library",   url: "https://wol.jw.org",                            icon: "building.columns.fill", tileColor: Color(hex: "#5B8EC4"), iconColor: .white),
        WebLink(title: "Donations",        url: "https://donate.jw.org",                         icon: "hand.raised.fill",      tileColor: Color(hex: "#6A9EC4"), iconColor: .white),
        WebLink(title: "Help",             url: "https://www.jw.org/en/jehovahs-witnesses/faq/", icon: "questionmark.circle",   tileColor: Color(hex: "#C7C7CC"), iconColor: Color(hex: "#3C3C43")),
        WebLink(title: "News",             url: "https://www.jw.org/en/news/",                   icon: "newspaper.fill",        tileColor: Color(hex: "#5E8C61"), iconColor: .white),
        WebLink(title: "Contact Us",       url: "https://www.jw.org/en/contact/",                icon: "envelope.fill",         tileColor: Color(hex: "#7B68A0"), iconColor: .white),
        WebLink(title: "About Us",         url: "https://www.jw.org/en/jehovahs-witnesses/",     icon: "info.circle.fill",      tileColor: Color(hex: "#5A8A9E"), iconColor: .white),
    ]

    private var adaptiveColumns: [GridItem] {
#if os(macOS)
        [GridItem(.adaptive(minimum: 130))]
#else
        [GridItem(.adaptive(minimum: 110))]
#endif
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Personal Study")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            // MARK: Section tab row (5 icons)
            HStack(spacing: 0) {
                ForEach(StudySection.allCases, id: \.self) { sec in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { selectedSection = sec }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: sec.systemImage)
                                .font(.system(size: 15, weight: selectedSection == sec ? .semibold : .regular))
                            Text(sec.rawValue)
                                .font(.system(size: 9, weight: selectedSection == sec ? .semibold : .regular))
                        }
                        .foregroundStyle(selectedSection == sec ? AppTheme.accent : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedSection == sec
                                ? AppTheme.accent.opacity(0.12)
                                : Color.clear
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(AppTheme.surface)

            Divider()

            // MARK: Content
            switch selectedSection {
            case .links:     linksView
            case .notes:     NotesView()
            case .playlists: PlaylistsView()
            case .history:   HistoryView()
            case .settings:  SettingsView()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: Links grid

    private var linksView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Links")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                LazyVGrid(columns: adaptiveColumns, spacing: 14) {
                    ForEach(webLinks) { link in
                        WebLinkCard(
                            title: link.title,
                            urlString: link.url,
                            icon: link.icon,
                            tileColor: link.tileColor,
                            iconColor: link.iconColor
                        ) {
                            if let url = URL(string: link.url) {
                                tabManager.openInNewTab(url: url, title: link.title)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
    }
}
