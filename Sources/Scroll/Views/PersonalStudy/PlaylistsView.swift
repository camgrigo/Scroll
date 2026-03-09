import SwiftUI
import SwiftData

// MARK: - PlaylistsView

struct PlaylistsView: View {
    @Query(sort: \Playlist.createdAt, order: .reverse) var playlists: [Playlist]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var tabManager: TabManager

    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var expandedPlaylistID: UUID? = nil

    private var readingPlaylists: [Playlist] {
        playlists.filter { pl in pl.items.allSatisfy { $0.type == "reading" } || pl.items.isEmpty }
    }

    private var mediaPlaylists: [Playlist] {
        playlists.filter { pl in pl.items.contains { $0.type == "audio" || $0.type == "video" } }
    }

    var body: some View {
        List {
            // MARK: Reading
            Section(header: sectionHeader("Reading")) {
                playlistRows(readingPlaylists)
            }

            // MARK: Audio / Video
            Section(header: sectionHeader("Audio & Video")) {
                playlistRows(mediaPlaylists)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newPlaylistName = ""
                    showCreatePlaylist = true
                } label: {
                    Label("New Playlist", systemImage: "plus")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .alert("New Playlist", isPresented: $showCreatePlaylist) {
            TextField("Playlist name", text: $newPlaylistName)
            Button("Create") { createPlaylist() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func playlistRows(_ list: [Playlist]) -> some View {
        if list.isEmpty {
            Text("No playlists yet")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .listRowBackground(Color.clear)
        } else {
            ForEach(list) { playlist in
                PlaylistRow(
                    playlist: playlist,
                    isExpanded: expandedPlaylistID == playlist.id
                ) {
                    withAnimation { expandedPlaylistID = expandedPlaylistID == playlist.id ? nil : playlist.id }
                } onOpenItem: { item in
                    if let url = URL(string: item.url) {
                        tabManager.openInNewTab(url: url, title: item.title)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(playlist)
                        try? modelContext.save()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.uppercaseSmallCaps())
            .foregroundStyle(AppTheme.textSecondary)
    }

    private func createPlaylist() {
        guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let pl = Playlist(name: newPlaylistName)
        modelContext.insert(pl)
        try? modelContext.save()
    }
}

// MARK: - PlaylistRow

struct PlaylistRow: View {
    let playlist: Playlist
    let isExpanded: Bool
    var onTap: () -> Void
    var onOpenItem: (PlaylistItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showAddItem = false
    @State private var newItemTitle = ""
    @State private var newItemURL   = ""
    @State private var newItemType  = "reading"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onTap) {
                HStack {
                    Image(systemName: "music.note.list")
                        .foregroundStyle(AppTheme.accent)
                    Text(playlist.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("\(playlist.items.count) items")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Items
                ForEach(playlist.items.sorted { $0.order < $1.order }) { item in
                    HStack {
                        Image(systemName: itemIcon(item.type))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 20)
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        Spacer()
                        Button { onOpenItem(item) } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(AppTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 20)
                    .padding(.vertical, 2)
                }

                // Add item
                Button {
                    newItemTitle = ""
                    newItemURL   = ""
                    newItemType  = "reading"
                    showAddItem  = true
                } label: {
                    Label("Add item", systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
                .padding(.leading, 20)
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showAddItem) {
            addItemSheet
        }
    }

    private func itemIcon(_ type: String) -> String {
        switch type {
        case "audio":   return "music.note"
        case "video":   return "play.rectangle"
        default:        return "doc.text"
        }
    }

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section("Item details") {
                    TextField("Title", text: $newItemTitle)
                    TextField("URL", text: $newItemURL)
#if os(iOS)
                        .keyboardType(.URL)
#endif
                        .autocorrectionDisabled()
                    Picker("Type", selection: $newItemType) {
                        Text("Reading").tag("reading")
                        Text("Audio").tag("audio")
                        Text("Video").tag("video")
                    }
                }
            }
            .navigationTitle("Add Item")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItemToPlaylist()
                        showAddItem = false
                    }
                    .disabled(newItemTitle.isEmpty || newItemURL.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddItem = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addItemToPlaylist() {
        let item = PlaylistItem(
            title: newItemTitle,
            url: newItemURL,
            type: newItemType,
            order: playlist.items.count,
            playlist: playlist
        )
        modelContext.insert(item)
        playlist.items.append(item)
        try? modelContext.save()
    }
}
