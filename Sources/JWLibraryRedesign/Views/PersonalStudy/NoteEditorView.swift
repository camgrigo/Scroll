import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - NoteEditorView

struct NoteEditorView: View {
    @Bindable var note: Note
    let isNew: Bool

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title:          String = ""
    @State private var attributedText: NSAttributedString = NSAttributedString()
    @State private var verseRef:       String = ""
    @State private var showVerseField  = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Meta bar (date, publication link, verse ref toggle)
                HStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    if let pub = note.publicationURL,
                       !pub.isEmpty,
                       let host = URL(string: pub)?.host {
                        Text("·").foregroundStyle(AppTheme.textSecondary)
                        Text(host)
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.28)) { showVerseField.toggle() }
                    } label: {
                        Image(systemName: showVerseField ? "book.closed.fill" : "book.closed")
                            .font(.system(size: 14))
                            .foregroundStyle(showVerseField ? AppTheme.accent : AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Link verse reference")
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // MARK: Verse reference field
                if showVerseField {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.accent)
                        TextField("e.g. John 3:16", text: $verseRef)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.text)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.surface)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: Title — Apple Notes large-bold style, no visible border
                TextField("Title", text: $title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .submitLabel(.next)

                Divider()
                    .background(Color(white: 0.15))
                    .padding(.horizontal, 16)

                // MARK: Rich-text body + formatting toolbar
                RichTextEditor(
                    attributedText: $attributedText,
                    placeholder: "Start writing…",
                    onTextChange: { _ in }
                )
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveAndDismiss() }
                        .foregroundStyle(AppTheme.accent)
                        .bold()
                }
#if os(iOS)
                ToolbarItem(placement: .bottomBar) {
                    if !isNew {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
#else
                ToolbarItem(placement: .destructiveAction) {
                    if !isNew {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete", systemImage: "trash").foregroundStyle(.red)
                        }
                    }
                }
#endif
            }
            .onAppear { loadNote() }
            .confirmationDialog("Delete this note?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(note)
                    try? modelContext.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: isNew ? Date() : note.updatedAt)
    }

    private func loadNote() {
        title    = note.title
        verseRef = note.verseReference ?? ""
        showVerseField = !(note.verseReference?.isEmpty ?? true)

        // Prefer stored RTF; fall back to plain text
        if let rtfData = note.contentRTF,
           let attr = NSAttributedString.fromRTF(rtfData) {
            attributedText = attr
        } else if !note.content.isEmpty {
#if os(iOS)
            attributedText = NSAttributedString(
                string: note.content,
                attributes: [.font: UIFont.systemFont(ofSize: 17),
                             .foregroundColor: UIColor(white: 0.91, alpha: 1)]
            )
#else
            attributedText = NSAttributedString(
                string: note.content,
                attributes: [.font: NSFont.systemFont(ofSize: 15),
                             .foregroundColor: NSColor(white: 0.91, alpha: 1)]
            )
#endif
        }
    }

    private func saveAndDismiss() {
        note.title          = title.isEmpty ? "Untitled" : title
        note.contentRTF     = attributedText.rtfData
        note.content        = attributedText.string   // plain-text for search
        note.verseReference = verseRef.isEmpty ? nil : verseRef
        note.updatedAt      = Date()
        if isNew { modelContext.insert(note) }
        try? modelContext.save()
        dismiss()
    }
}
