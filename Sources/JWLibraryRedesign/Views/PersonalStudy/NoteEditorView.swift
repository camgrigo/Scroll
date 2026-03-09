import SwiftUI
import SwiftData

// MARK: - NoteEditorView

struct NoteEditorView: View {
    @Bindable var note: Note
    let isNew: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var verseRef: String = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title field
                TextField("Title", text: $title)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.text)
                    .padding(.horizontal)
                    .padding(.top, 12)

                Divider().padding(.horizontal)

                // Verse reference
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundStyle(AppTheme.accent)
                    TextField("Verse reference (e.g. John 3:16)", text: $verseRef)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider().padding(.horizontal)

                // Content
                TextEditor(text: $content)
                    .font(.body)
                    .foregroundStyle(AppTheme.text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 12)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "New Note" : "Edit Note")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .foregroundStyle(AppTheme.accent)
                        .bold()
                }
#if os(iOS)
                ToolbarItem(placement: .bottomBar) {
                    if !isNew {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
#else
                ToolbarItem(placement: .destructiveAction) {
                    if !isNew {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
#endif
            }
            .onAppear {
                title    = note.title
                content  = note.content
                verseRef = note.verseReference ?? ""
            }
            .confirmationDialog("Delete this note?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
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

    private func saveAndDismiss() {
        note.title          = title
        note.content        = content
        note.verseReference = verseRef.isEmpty ? nil : verseRef
        note.updatedAt      = Date()

        if isNew {
            modelContext.insert(note)
        }
        try? modelContext.save()
        dismiss()
    }
}
