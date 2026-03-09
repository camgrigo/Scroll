import SwiftUI
import SwiftData

// MARK: - NotesView

struct NotesView: View {
    @Query(sort: \Note.updatedAt, order: .reverse) var notes: [Note]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedNote: Note? = nil
    @State private var showNewNote = false

    private var filteredNotes: [Note] {
        if searchText.isEmpty { return notes }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            ($0.verseReference?.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    private var groupedNotes: [(key: String, notes: [Note])] {
        let grouped = Dictionary(grouping: filteredNotes) { note -> String in
            sectionTitle(for: note.updatedAt)
        }
        let order = ["Today", "Yesterday", "This Week", "This Month", "Older"]
        return order.compactMap { key in
            guard let ns = grouped[key], !ns.isEmpty else { return nil }
            return (key: key, notes: ns)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(groupedNotes, id: \.key) { group in
                    Section(header: sectionHeader(group.key)) {
                        ForEach(group.notes) { note in
                            NoteRow(note: note)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedNote = note }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        modelContext.delete(note)
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
            .searchable(text: $searchText, prompt: "Search notes…")
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)

            // Floating add button
            Button {
                showNewNote = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(AppTheme.accent))
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 8)
            }
            .buttonStyle(.plain)
            .padding(20)
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(note: note, isNew: false)
        }
        .sheet(isPresented: $showNewNote) {
            let note = Note()
            NoteEditorView(note: note, isNew: true)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.uppercaseSmallCaps())
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.vertical, 2)
    }

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if let week = cal.dateInterval(of: .weekOfYear, for: Date()), week.contains(date) {
            return "This Week"
        }
        if let month = cal.dateInterval(of: .month, for: Date()), month.contains(date) {
            return "This Month"
        }
        return "Older"
    }
}

// MARK: - NoteRow

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(note.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let ref = note.verseReference, !ref.isEmpty {
                Label(ref, systemImage: "book.closed")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }

            Text(note.content)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, 6)
        .listRowBackground(AppTheme.surface)
    }
}
