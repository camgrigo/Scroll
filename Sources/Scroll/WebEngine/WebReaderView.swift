import SwiftUI
import WebKit
import SwiftData

// MARK: - JavaScript injection source

private let textSelectionScript = """
(function() {
    if (window.__jwSelectionInstalled) return;
    window.__jwSelectionInstalled = true;

    document.addEventListener('selectionchange', function() {
        var selection = window.getSelection();
        if (selection && selection.toString().length > 0) {
            window.webkit.messageHandlers.textSelected.postMessage({
                text: selection.toString(),
                range: selection.getRangeAt(0).toString()
            });
        }
    });

    window.applyHighlight = function(color) {
        var selection = window.getSelection();
        if (!selection || !selection.rangeCount) return;
        var range = selection.getRangeAt(0);
        var span = document.createElement('span');
        span.style.backgroundColor = color;
        span.style.borderRadius = '2px';
        span.className = 'jw-highlight';
        try { range.surroundContents(span); } catch(e) {}
        selection.removeAllRanges();
    };
})();
"""

// MARK: - WebReaderView (cross-platform entry point)

struct WebReaderView: View {
    let tab: TabItem
    let webViewStore: WebViewStore

    @Environment(\.modelContext) private var modelContext

    @State private var showHighlightToolbar = false
    @State private var selectedText: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
#if os(iOS)
            IOSWebView(
                tab: tab,
                store: webViewStore,
                onTextSelected: { text in
                    selectedText = text
                    showHighlightToolbar = !text.isEmpty
                },
                onPageLoaded: { reapplyHighlights() }
            )
#else
            MacWebView(
                tab: tab,
                store: webViewStore,
                onTextSelected: { text in
                    selectedText = text
                    showHighlightToolbar = !text.isEmpty
                },
                onPageLoaded: { reapplyHighlights() }
            )
#endif
            // Listener for back/forward notifications
            Color.clear
                .onReceive(NotificationCenter.default.publisher(for: .webViewGoBack)) { notif in
                    if let id = notif.object as? UUID, id == tab.id {
                        webViewStore.webViews[id]?.goBack()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .webViewGoForward)) { notif in
                    if let id = notif.object as? UUID, id == tab.id {
                        webViewStore.webViews[id]?.goForward()
                    }
                }

            if showHighlightToolbar && !selectedText.isEmpty {
                HighlightToolbar(
                    selectedText: selectedText,
                    pageURL: tab.currentURL?.absoluteString ?? "",
                    pageTitle: tab.title,
                    webViewStore: webViewStore
                ) {
                    showHighlightToolbar = false
                    selectedText = ""
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: showHighlightToolbar)
                .padding(.bottom, 16)
            }
        }
        .onChange(of: tab.isReaderMode) { _, enabled in
            handleReaderModeChange(enabled)
        }
        .onChange(of: tab.currentURL) { _, _ in
            // Leaving a page resets reader mode
            if tab.isReaderMode { tab.isReaderMode = false }
        }
    }

    // MARK: - Highlight re-application

    private func reapplyHighlights() {
        guard let urlStr = tab.currentURL?.absoluteString else { return }
        let desc = FetchDescriptor<Highlight>(
            predicate: #Predicate { $0.publicationURL == urlStr }
        )
        guard let highlights = try? modelContext.fetch(desc), !highlights.isEmpty else { return }

        let colorMap: [String: String] = [
            "yellow": "#FFE082CC", "orange": "#FFAB40CC", "pink":   "#F48FB1CC",
            "blue":   "#81D4FACC", "purple": "#CE93D8CC", "green":  "#A5D6A7CC"
        ]
        for h in highlights {
            let color = colorMap[h.colorName] ?? "#FFE082CC"
            let escaped = h.selectedText
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'",  with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            let js = """
            (function(){
                var t='\(escaped)',c='\(color)';
                var w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT,null),n;
                while(n=w.nextNode()){
                    var i=n.textContent.indexOf(t);
                    if(i>=0&&n.parentNode.className!=='jw-highlight'){
                        var r=document.createRange();
                        r.setStart(n,i);r.setEnd(n,i+t.length);
                        var s=document.createElement('span');
                        s.style.backgroundColor=c;s.style.borderRadius='2px';
                        s.className='jw-highlight';
                        try{r.surroundContents(s);}catch(e){}break;
                    }
                }
            })();
            """
            webViewStore.evaluateJavaScript(js, for: tab.id)
        }
    }

    // MARK: - Reader mode

    private func handleReaderModeChange(_ enabled: Bool) {
        guard let wv = webViewStore.webViews[tab.id] else { return }
        if enabled {
            wv.evaluateJavaScript(ReaderModeService.extractionJS) { result, _ in
                guard let jsonStr = result as? String,
                      let data    = jsonStr.data(using: .utf8),
                      let obj     = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                      let content = obj["content"]
                else {
                    DispatchQueue.main.async { self.tab.isReaderMode = false }
                    return
                }
                let title = obj["title"] ?? self.tab.title
                let html  = ReaderModeService.readerHTML(title: title, content: content)
                DispatchQueue.main.async { wv.loadHTMLString(html, baseURL: wv.url) }
            }
        } else {
            if let url = tab.currentURL {
                wv.load(URLRequest(url: url))
            }
        }
    }
}

// MARK: - Shared web-view store

@Observable
final class WebViewStore {
    var webViews: [UUID: WKWebView] = [:]

    func webView(for tab: TabItem, config: WKWebViewConfiguration) -> WKWebView {
        if let existing = webViews[tab.id] { return existing }
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        webViews[tab.id] = wv
        return wv
    }

    func evaluateJavaScript(_ js: String, for tabID: UUID) {
        webViews[tabID]?.evaluateJavaScript(js, completionHandler: nil)
    }
}

// MARK: - Shared WKWebView coordinator

final class WebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let tab: TabItem
    var onTextSelected: (String) -> Void
    var onPageLoaded: (() -> Void)?

    init(tab: TabItem, onTextSelected: @escaping (String) -> Void) {
        self.tab = tab
        self.onTextSelected = onTextSelected
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab.isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        tab.isLoading    = false
        tab.title        = webView.title ?? tab.title
        tab.currentURL   = webView.url  ?? tab.currentURL
        tab.canGoBack    = webView.canGoBack
        tab.canGoForward = webView.canGoForward
        tab.lastAccessedAt = Date()
        DispatchQueue.main.async { self.onPageLoaded?() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        tab.isLoading = false
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        tab.isLoading = false
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    // MARK: WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard message.name == "textSelected",
              let body = message.body as? [String: Any],
              let text = body["text"] as? String else { return }
        DispatchQueue.main.async { self.onTextSelected(text) }
    }
}

// MARK: - Shared WKWebViewConfiguration factory

private func makeWebConfig(coordinator: WebCoordinator) -> WKWebViewConfiguration {
    let config = WKWebViewConfiguration()
#if os(iOS)
    config.allowsInlineMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []
#endif
    let script = WKUserScript(
        source: textSelectionScript,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(script)
    config.userContentController.add(coordinator, name: "textSelected")
    return config
}

// MARK: - iOS implementation

#if os(iOS)

struct IOSWebView: UIViewControllerRepresentable {
    let tab: TabItem
    let store: WebViewStore
    var onTextSelected: (String) -> Void
    var onPageLoaded: (() -> Void)?

    func makeCoordinator() -> WebCoordinator {
        WebCoordinator(tab: tab, onTextSelected: onTextSelected)
    }

    func makeUIViewController(context: Context) -> WebContainerViewController {
        WebContainerViewController(store: store, coordinator: context.coordinator)
    }

    func updateUIViewController(_ vc: WebContainerViewController, context: Context) {
        context.coordinator.onPageLoaded = onPageLoaded
        vc.switchToTab(tab, coordinator: context.coordinator)
    }
}

final class WebContainerViewController: UIViewController {
    private let store: WebViewStore
    private var coordinator: WebCoordinator
    private var currentTabID: UUID?

    init(store: WebViewStore, coordinator: WebCoordinator) {
        self.store = store
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    func switchToTab(_ tab: TabItem, coordinator: WebCoordinator) {
        self.coordinator = coordinator
        store.webViews.values.forEach { $0.isHidden = true }

        let config = makeWebConfig(coordinator: coordinator)
        let wv = store.webView(for: tab, config: config)
        wv.navigationDelegate = coordinator

        if wv.superview == nil {
            view.addSubview(wv)
            wv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                wv.topAnchor.constraint(equalTo: view.topAnchor),
                wv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                wv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }

        wv.isHidden = false

        if currentTabID != tab.id {
            currentTabID = tab.id
            if let url = tab.currentURL, wv.url == nil {
                wv.load(URLRequest(url: url))
            } else if let url = tab.currentURL, wv.url != url {
                wv.load(URLRequest(url: url))
            }
        }
    }
}

#else

// MARK: - macOS implementation

struct MacWebView: NSViewRepresentable {
    let tab: TabItem
    let store: WebViewStore
    var onTextSelected: (String) -> Void
    var onPageLoaded: (() -> Void)?

    func makeCoordinator() -> WebCoordinator {
        WebCoordinator(tab: tab, onTextSelected: onTextSelected)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = makeWebConfig(coordinator: context.coordinator)
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        wv.navigationDelegate = context.coordinator
        context.coordinator.onPageLoaded = onPageLoaded
        store.webViews[tab.id] = wv
        if let url = tab.currentURL {
            wv.load(URLRequest(url: url))
        }
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        context.coordinator.onPageLoaded = onPageLoaded
        wv.navigationDelegate = context.coordinator
        if let url = tab.currentURL, wv.url != url {
            wv.load(URLRequest(url: url))
        }
    }
}

#endif
