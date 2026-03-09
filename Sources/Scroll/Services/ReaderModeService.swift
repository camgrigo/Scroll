import Foundation

// MARK: - ReaderModeService

enum ReaderModeService {

    // MARK: JavaScript – extracts the main article content from the live page

    static let extractionJS = """
    (function() {
        var selectors = [
            'article',
            '.article',
            '#article',
            '.bodyTxt',
            '.synopsis',
            '[role="article"]',
            '[class*="articleBody"]',
            'main article',
            '[role="main"] article',
            'main',
            '[role="main"]',
            '.content',
            '#content'
        ];
        var content = null;
        var title = document.title;
        for (var i = 0; i < selectors.length; i++) {
            var el = document.querySelector(selectors[i]);
            if (el && el.innerText.trim().length > 300) {
                var cloned = el.cloneNode(true);
                ['nav','header','footer','aside','.navigation','.sidebar',
                 '[class*="share"]','.ad','[class*="ad-"]',
                 '[class*="related"]','.cookie-banner','.modal','.overlay']
                    .forEach(function(s) {
                        cloned.querySelectorAll(s).forEach(function(n){ n.remove(); });
                    });
                content = cloned.innerHTML;
                break;
            }
        }
        if (!content) {
            var body = document.body.cloneNode(true);
            ['nav','header','footer','script','style','aside'].forEach(function(s) {
                body.querySelectorAll(s).forEach(function(n){ n.remove(); });
            });
            content = body.innerHTML;
        }
        return JSON.stringify({ title: title, content: content });
    })();
    """

    // MARK: Clean reader HTML template

    static func readerHTML(title: String, content: String, fontSize: Int = 17) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0">
        <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #0A0F1E;
            color: #E8EAED;
            font-family: -apple-system, 'SF Pro Text', Georgia, serif;
            font-size: \(fontSize)px;
            line-height: 1.78;
            padding: 28px 20px 80px;
            max-width: 720px;
            margin: 0 auto;
        }
        h1.reader-title {
            font-size: 1.7em;
            font-weight: 700;
            color: #E8EAED;
            margin-bottom: 0.8em;
            line-height: 1.22;
        }
        h1, h2 { font-size: 1.35em; font-weight: 700; margin: 1.4em 0 0.4em; color: #E8EAED; }
        h3     { font-size: 1.1em;  font-weight: 600; margin: 1.1em 0 0.3em; color: #E8EAED; }
        h4, h5, h6 { font-size: 1em; font-weight: 600; margin: 0.9em 0 0.2em; color: #9AA0A6; }
        p { margin: 0.7em 0; }
        a { color: #D4A827; text-decoration: none; }
        a:hover { text-decoration: underline; }
        img { max-width: 100%; height: auto; border-radius: 8px; margin: 1em 0; display: block; }
        blockquote {
            border-left: 3px solid #D4A827;
            padding: 0.3em 0 0.3em 1em;
            margin: 1.1em 0;
            color: #9AA0A6;
            font-style: italic;
        }
        ul, ol { padding-left: 1.6em; margin: 0.7em 0; }
        li { margin: 0.35em 0; }
        .jw-highlight { border-radius: 2px; }
        nav, header, footer, aside, .navigation, .sidebar,
        [class*="share"], [class*="ad-"], [class*="related"],
        .cookie-banner, .modal, .overlay, .popup { display: none !important; }
        </style>
        </head>
        <body>
        <h1 class="reader-title">\(title.htmlEscaped)</h1>
        \(content)
        </body>
        </html>
        """
    }
}

private extension String {
    var htmlEscaped: String {
        self
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
