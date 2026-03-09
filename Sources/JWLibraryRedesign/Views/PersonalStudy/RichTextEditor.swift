import SwiftUI

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - RichTextEditorState
// Observable bridge between the SwiftUI toolbar and the platform text view.

@Observable
final class RichTextEditorState {
    var isBold          = false
    var isItalic        = false
    var isUnderline     = false
    var isStrikethrough = false
    var headingLevel    = 0   // 0 = body, 1 = title, 2 = heading

    // Actions injected by the native-view coordinator
    var applyBold:          (() -> Void)?
    var applyItalic:        (() -> Void)?
    var applyUnderline:     (() -> Void)?
    var applyStrikethrough: (() -> Void)?
    var applyHeading:       ((Int) -> Void)?
    var insertBullet:       (() -> Void)?
    var insertNumbered:     (() -> Void)?
    var insertChecklist:    (() -> Void)?
}

// MARK: - RichTextEditor

struct RichTextEditor: View {
    @Binding var attributedText: NSAttributedString
    var placeholder: String = "Start writing…"
    var onTextChange: ((NSAttributedString) -> Void)?

    @State private var editorState = RichTextEditorState()

    var body: some View {
        VStack(spacing: 0) {
#if os(iOS)
            IOSRichTextView(
                attributedText: $attributedText,
                state: editorState,
                placeholder: placeholder,
                onTextChange: onTextChange
            )
#else
            MacRichTextView(
                attributedText: $attributedText,
                state: editorState,
                onTextChange: onTextChange
            )
#endif
            Divider()
                .background(Color(white: 0.18))

            RichTextFormattingToolbar(state: editorState)
        }
    }
}

// MARK: - Formatting toolbar

struct RichTextFormattingToolbar: View {
    let state: RichTextEditorState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {

                // Heading / text style menu
                Menu {
                    Button("Title")   { state.applyHeading?(1) }
                    Button("Heading") { state.applyHeading?(2) }
                    Button("Body")    { state.applyHeading?(0) }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "textformat.size")
                        Image(systemName: "chevron.down").font(.system(size: 9))
                    }
                    .toolbarBtn(active: state.headingLevel != 0)
                }
                .buttonStyle(.plain)

                toolbarDivider()

                Button { state.applyBold?() } label: {
                    Image(systemName: "bold").toolbarBtn(active: state.isBold)
                }
                .buttonStyle(.plain)
                .help("Bold")

                Button { state.applyItalic?() } label: {
                    Image(systemName: "italic").toolbarBtn(active: state.isItalic)
                }
                .buttonStyle(.plain)
                .help("Italic")

                Button { state.applyUnderline?() } label: {
                    Image(systemName: "underline").toolbarBtn(active: state.isUnderline)
                }
                .buttonStyle(.plain)
                .help("Underline")

                Button { state.applyStrikethrough?() } label: {
                    Image(systemName: "strikethrough").toolbarBtn(active: state.isStrikethrough)
                }
                .buttonStyle(.plain)
                .help("Strikethrough")

                toolbarDivider()

                Button { state.insertBullet?() } label: {
                    Image(systemName: "list.bullet").toolbarBtn(active: false)
                }
                .buttonStyle(.plain)
                .help("Bullet list")

                Button { state.insertNumbered?() } label: {
                    Image(systemName: "list.number").toolbarBtn(active: false)
                }
                .buttonStyle(.plain)
                .help("Numbered list")

                Button { state.insertChecklist?() } label: {
                    Image(systemName: "checklist").toolbarBtn(active: false)
                }
                .buttonStyle(.plain)
                .help("Checklist")
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .background(Color(hex: "#0D1424"))
    }

    private func toolbarDivider() -> some View {
        Rectangle()
            .fill(Color(white: 0.22))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 4)
    }
}

private extension View {
    func toolbarBtn(active: Bool) -> some View {
        self
            .font(.system(size: 15, weight: active ? .semibold : .regular))
            .foregroundStyle(active ? Color(hex: "#D4A827") : Color(hex: "#9AA0A6"))
            .frame(width: 36, height: 36)
            .background(
                active
                    ? AnyShapeStyle(Color(hex: "#D4A827").opacity(0.15))
                    : AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: 6)
            )
    }
}

// MARK: - NSAttributedString ↔ RTF helpers

extension NSAttributedString {
    var rtfData: Data? {
        guard length > 0 else { return nil }
        return try? data(
            from: NSRange(location: 0, length: length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    static func fromRTF(_ data: Data) -> NSAttributedString? {
        try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }
}

// ============================================================
// MARK: - iOS implementation
// ============================================================

#if os(iOS)

struct IOSRichTextView: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    let state: RichTextEditorState
    var placeholder: String
    var onTextChange: ((NSAttributedString) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 60, right: 8)
        tv.isEditable   = true
        tv.isSelectable = true
        tv.allowsEditingTextAttributes = true
        tv.delegate = context.coordinator

        // Default typing style
        tv.typingAttributes = context.coordinator.defaultAttributes

        // Load initial content or show placeholder
        if attributedText.length > 0 {
            tv.attributedText = attributedText
        } else {
            tv.attributedText = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(white: 0.38, alpha: 1),
                             .font: UIFont.systemFont(ofSize: 17)]
            )
            context.coordinator.showingPlaceholder = true
        }

        context.coordinator.textView = tv
        context.coordinator.wireActions()
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Only push external changes (e.g. loading an existing note)
        guard !context.coordinator.showingPlaceholder,
              attributedText.length > 0,
              tv.attributedText != attributedText else { return }
        let sel = tv.selectedRange
        tv.attributedText = attributedText
        tv.selectedRange  = sel
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: IOSRichTextView
        weak var textView: UITextView?
        var showingPlaceholder = false

        init(_ parent: IOSRichTextView) { self.parent = parent }

        // MARK: Default attributes

        var defaultAttributes: [NSAttributedString.Key: Any] {
            [.font: UIFont.systemFont(ofSize: 17, weight: .regular),
             .foregroundColor: UIColor(white: 0.91, alpha: 1)]
        }
        func titleFont()   -> UIFont { .systemFont(ofSize: 26, weight: .bold) }
        func headingFont() -> UIFont { .systemFont(ofSize: 20, weight: .semibold) }
        func bodyFont()    -> UIFont { .systemFont(ofSize: 17, weight: .regular) }

        // MARK: Wire closures → RichTextEditorState

        func wireActions() {
            let s = parent.state
            s.applyBold          = { [weak self] in self?.toggleBold() }
            s.applyItalic        = { [weak self] in self?.toggleItalic() }
            s.applyUnderline     = { [weak self] in self?.toggleUnderline() }
            s.applyStrikethrough = { [weak self] in self?.toggleStrikethrough() }
            s.applyHeading       = { [weak self] level in self?.applyHeading(level) }
            s.insertBullet       = { [weak self] in self?.insertPrefix("• ") }
            s.insertNumbered     = { [weak self] in self?.insertNumberedItem() }
            s.insertChecklist    = { [weak self] in self?.insertPrefix("☐ ") }
        }

        // MARK: UITextViewDelegate

        func textViewDidBeginEditing(_ tv: UITextView) {
            if showingPlaceholder {
                tv.attributedText = NSAttributedString(string: "", attributes: defaultAttributes)
                showingPlaceholder = false
            }
        }

        func textViewDidChange(_ tv: UITextView) {
            parent.attributedText = tv.attributedText
            parent.onTextChange?(tv.attributedText)
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            syncToolbarState(tv)
        }

        // MARK: Sync toolbar state from current attributes

        private func syncToolbarState(_ tv: UITextView) {
            let attrs: [NSAttributedString.Key: Any]
            if tv.selectedRange.length > 0,
               tv.textStorage.length > tv.selectedRange.location {
                attrs = tv.textStorage.attributes(at: tv.selectedRange.location, effectiveRange: nil)
            } else {
                attrs = tv.typingAttributes
            }
            if let font = attrs[.font] as? UIFont {
                let t = font.fontDescriptor.symbolicTraits
                parent.state.isBold   = t.contains(.traitBold)
                parent.state.isItalic = t.contains(.traitItalic)
            }
            parent.state.isUnderline    = (attrs[.underlineStyle]     as? Int ?? 0) != 0
            parent.state.isStrikethrough = (attrs[.strikethroughStyle] as? Int ?? 0) != 0
        }

        // MARK: Format actions

        private func toggleBold()   { toggleTrait(.traitBold) }
        private func toggleItalic() { toggleTrait(.traitItalic) }

        private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
            guard let tv = textView else { return }
            if tv.selectedRange.length == 0 {
                var a = tv.typingAttributes
                let f = (a[.font] as? UIFont) ?? bodyFont()
                let d = f.fontDescriptor
                if let nd = d.withSymbolicTraits(
                    d.symbolicTraits.contains(trait)
                        ? d.symbolicTraits.subtracting(trait)
                        : d.symbolicTraits.union(trait)
                ) {
                    a[.font] = UIFont(descriptor: nd, size: f.pointSize)
                }
                tv.typingAttributes = a
            } else {
                applyToSelection { storage, range in
                    storage.enumerateAttribute(.font, in: range) { val, sub, _ in
                        let f  = (val as? UIFont) ?? self.bodyFont()
                        let d  = f.fontDescriptor
                        let nd = d.withSymbolicTraits(
                            d.symbolicTraits.contains(trait)
                                ? d.symbolicTraits.subtracting(trait)
                                : d.symbolicTraits.union(trait)
                        ) ?? d
                        storage.addAttribute(.font,
                                             value: UIFont(descriptor: nd, size: f.pointSize),
                                             range: sub)
                    }
                }
            }
            syncToolbarState(tv)
        }

        private func toggleUnderline()     { toggleAttribute(.underlineStyle) }
        private func toggleStrikethrough() { toggleAttribute(.strikethroughStyle) }

        private func toggleAttribute(_ key: NSAttributedString.Key) {
            guard let tv = textView else { return }
            let value = NSUnderlineStyle.single.rawValue
            if tv.selectedRange.length == 0 {
                var a = tv.typingAttributes
                let cur = a[key] as? Int ?? 0
                a[key] = cur == 0 ? value : 0
                tv.typingAttributes = a
            } else {
                applyToSelection { storage, range in
                    var allHave = true
                    storage.enumerateAttribute(key, in: range) { v, _, _ in
                        if (v as? Int ?? 0) == 0 { allHave = false }
                    }
                    if allHave {
                        storage.removeAttribute(key, range: range)
                    } else {
                        storage.addAttribute(key, value: value, range: range)
                    }
                }
            }
            syncToolbarState(tv)
        }

        private func applyHeading(_ level: Int) {
            guard let tv = textView else { return }
            let font: UIFont
            switch level {
            case 1:  font = titleFont()
            case 2:  font = headingFont()
            default: font = bodyFont()
            }
            parent.state.headingLevel = level
            if tv.selectedRange.length > 0 {
                applyToSelection { storage, range in
                    storage.addAttribute(.font, value: font, range: range)
                }
            } else {
                var a = tv.typingAttributes
                a[.font] = font
                tv.typingAttributes = a
            }
        }

        private func insertPrefix(_ prefix: String) {
            guard let tv = textView else { return }
            let loc = tv.selectedRange.location
            let nsText = tv.text as NSString
            var lineStart = 0
            nsText.getLineStart(&lineStart, end: nil, contentsEnd: nil,
                                for: NSRange(location: loc, length: 0))
            let attr = NSAttributedString(string: prefix, attributes: tv.typingAttributes)
            tv.textStorage.beginEditing()
            tv.textStorage.insert(attr, at: lineStart)
            tv.textStorage.endEditing()
            tv.selectedRange = NSRange(location: loc + prefix.count, length: 0)
            parent.attributedText = tv.attributedText
            parent.onTextChange?(tv.attributedText)
        }

        private func insertNumberedItem() {
            guard let tv = textView else { return }
            let lines = tv.text.components(separatedBy: "\n")
            var num = 1
            for line in lines.reversed() {
                if let r = line.range(of: #"^(\d+)\."#, options: .regularExpression),
                   let n = Int(String(line[r]).dropLast()) {
                    num = n + 1; break
                }
            }
            insertPrefix("\(num). ")
        }

        // MARK: Helper

        private func applyToSelection(_ apply: (NSTextStorage, NSRange) -> Void) {
            guard let tv = textView, tv.selectedRange.length > 0 else { return }
            let storage = tv.textStorage
            storage.beginEditing()
            apply(storage, tv.selectedRange)
            storage.endEditing()
            parent.attributedText = tv.attributedText
            parent.onTextChange?(tv.attributedText)
        }
    }
}

// ============================================================
// MARK: - macOS implementation
// ============================================================

#else

struct MacRichTextView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    let state: RichTextEditorState
    var onTextChange: ((NSAttributedString) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let tv = scrollView.documentView as? NSTextView else { return scrollView }
        tv.backgroundColor   = .clear
        tv.textColor         = NSColor(white: 0.91, alpha: 1)
        tv.isEditable        = true
        tv.isSelectable      = true
        tv.isRichText        = true
        tv.allowsUndo        = true
        tv.usesFontPanel     = true
        tv.font              = .systemFont(ofSize: 15)
        tv.textContainerInset = NSSize(width: 8, height: 12)
        tv.delegate          = context.coordinator
        if attributedText.length > 0 {
            tv.textStorage?.setAttributedString(attributedText)
        }
        context.coordinator.textView = tv
        context.coordinator.wireActions()
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        if attributedText.length > 0, tv.attributedString() != attributedText {
            tv.textStorage?.setAttributedString(attributedText)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacRichTextView
        weak var textView: NSTextView?

        init(_ parent: MacRichTextView) { self.parent = parent }

        func wireActions() {
            let s = parent.state
            s.applyBold          = { [weak self] in self?.toggleBold() }
            s.applyItalic        = { [weak self] in self?.toggleItalic() }
            s.applyUnderline     = { [weak self] in self?.toggleUnderline() }
            s.applyStrikethrough = { [weak self] in self?.toggleStrikethrough() }
            s.applyHeading       = { [weak self] level in self?.applyHeading(level) }
            s.insertBullet       = { [weak self] in self?.insertPrefix("• ") }
            s.insertNumbered     = { [weak self] in self?.insertPrefix("1. ") }
            s.insertChecklist    = { [weak self] in self?.insertPrefix("☐ ") }
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.attributedText = tv.attributedString()
            parent.onTextChange?(tv.attributedString())
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            syncToolbarState(tv)
        }

        private func syncToolbarState(_ tv: NSTextView) {
            let range = tv.selectedRange()
            let attrs: [NSAttributedString.Key: Any] = range.length > 0
                ? tv.attributedString().attributes(at: range.location, effectiveRange: nil)
                : tv.typingAttributes
            if let font = attrs[.font] as? NSFont {
                let traits = NSFontManager.shared.traits(of: font)
                parent.state.isBold   = traits.contains(.boldFontMask)
                parent.state.isItalic = traits.contains(.italicFontMask)
            }
            parent.state.isUnderline     = (attrs[.underlineStyle]     as? Int ?? 0) != 0
            parent.state.isStrikethrough = (attrs[.strikethroughStyle] as? Int ?? 0) != 0
        }

        private func toggleBold() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            let range = tv.selectedRange()
            guard range.length > 0 else { parent.state.isBold = !parent.state.isBold; return }
            storage.beginEditing()
            storage.enumerateAttribute(.font, in: range) { val, r, _ in
                let base = (val as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
                let newFont = parent.state.isBold
                    ? NSFontManager.shared.convert(base, toNotHaveTrait: .boldFontMask)
                    : NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
                storage.addAttribute(.font, value: newFont, range: r)
            }
            storage.endEditing()
            parent.state.isBold = !parent.state.isBold
        }

        private func toggleItalic() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            let range = tv.selectedRange()
            guard range.length > 0 else { parent.state.isItalic = !parent.state.isItalic; return }
            storage.beginEditing()
            storage.enumerateAttribute(.font, in: range) { val, r, _ in
                let base = (val as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
                let newFont = parent.state.isItalic
                    ? NSFontManager.shared.convert(base, toNotHaveTrait: .italicFontMask)
                    : NSFontManager.shared.convert(base, toHaveTrait: .italicFontMask)
                storage.addAttribute(.font, value: newFont, range: r)
            }
            storage.endEditing()
            parent.state.isItalic = !parent.state.isItalic
        }

        private func toggleUnderline() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            let range = tv.selectedRange()
            guard range.length > 0 else { parent.state.isUnderline = !parent.state.isUnderline; return }
            let value: Int = parent.state.isUnderline ? 0 : NSUnderlineStyle.single.rawValue
            storage.beginEditing()
            storage.addAttribute(.underlineStyle, value: value, range: range)
            storage.endEditing()
            parent.state.isUnderline = !parent.state.isUnderline
        }

        private func toggleStrikethrough() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            let range = tv.selectedRange()
            var allHave = true
            storage.enumerateAttribute(.strikethroughStyle, in: range) { v, _, _ in
                if (v as? Int ?? 0) == 0 { allHave = false }
            }
            storage.beginEditing()
            if allHave {
                storage.removeAttribute(.strikethroughStyle, range: range)
            } else {
                storage.addAttribute(.strikethroughStyle,
                                     value: NSUnderlineStyle.single.rawValue, range: range)
            }
            storage.endEditing()
            parent.state.isStrikethrough = !parent.state.isStrikethrough
            parent.attributedText = tv.attributedString()
            parent.onTextChange?(tv.attributedString())
        }

        private func applyHeading(_ level: Int) {
            guard let tv = textView else { return }
            let font: NSFont
            switch level {
            case 1:  font = .systemFont(ofSize: 24, weight: .bold)
            case 2:  font = .systemFont(ofSize: 18, weight: .semibold)
            default: font = .systemFont(ofSize: 15, weight: .regular)
            }
            parent.state.headingLevel = level
            let range = tv.selectedRange()
            if range.length > 0 {
                tv.textStorage?.addAttribute(.font, value: font, range: range)
            } else {
                var a = tv.typingAttributes; a[.font] = font; tv.typingAttributes = a
            }
            parent.attributedText = tv.attributedString()
            parent.onTextChange?(tv.attributedString())
        }

        private func insertPrefix(_ prefix: String) {
            guard let tv = textView else { return }
            let loc  = tv.selectedRange().location
            let attr = NSAttributedString(string: prefix, attributes: tv.typingAttributes)
            tv.textStorage?.insert(attr, at: loc)
            parent.attributedText = tv.attributedString()
            parent.onTextChange?(tv.attributedString())
        }
    }
}

#endif
