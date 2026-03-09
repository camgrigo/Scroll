import SwiftUI
import SwiftData

// MARK: - HighlightToolbar

struct HighlightToolbar: View {
    let selectedText: String
    let pageURL: String
    let pageTitle: String
    let webViewStore: WebViewStore
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabManager: TabManager

    @State private var showNoteEditor = false
    @State private var noteForHighlight: Note? = nil

    private let colors: [(name: String, hex: String, display: Color)] = [
        ("yellow", "#FFE082CC", Color(hex: "#FFE082")),
        ("orange", "#FFAB40CC", Color(hex: "#FFAB40")),
        ("pink",   "#F48FB1CC", Color(hex: "#F48FB1")),
        ("blue",   "#81D4FACC", Color(hex: "#81D4FA")),
        ("purple", "#CE93D8CC", Color(hex: "#CE93D8")),
        ("green",  "#A5D6A7CC", Color(hex: "#A5D6A7")),
    ]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(colors, id: \.name) { item in
                Button {
                    applyHighlight(colorName: item.name, cssColor: item.hex)
                } label: {
                    Circle()
                        .fill(item.display)
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .frame(height: 24)
                .background(AppTheme.textSecondary)

            // Note button
            Button {
                let note = Note(
                    title: "Note on \(pageTitle)",
                    content: selectedText,
                    publicationURL: pageURL
                )
                noteForHighlight = note
                showNoteEditor = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(AppTheme.accentSoft)
                    .font(.system(size: 18))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)

            // Dismiss
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.surface.opacity(0.95))
                .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        )
        .sheet(isPresented: $showNoteEditor) {
            if let note = noteForHighlight {
                NoteEditorView(note: note, isNew: true)
            }
        }
    }

    // MARK: - Private

    private func applyHighlight(colorName: String, cssColor: String) {
        guard let tabID = tabManager.activeTabID else { return }

        // Apply visual highlight in the web view
        let js = "applyHighlight('\(cssColor)');"
        webViewStore.evaluateJavaScript(js, for: tabID)

        // Persist to SwiftData
        let highlight = Highlight(
            publicationURL: pageURL,
            selectedText: selectedText,
            colorName: colorName,
            pageTitle: pageTitle
        )
        modelContext.insert(highlight)
        try? modelContext.save()

        onDismiss()
    }
}
