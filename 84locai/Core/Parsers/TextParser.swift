import Foundation

struct TextParser {

    /// Read plain text or Markdown from a file URL
    static func parse(url: URL) -> String? {
        guard let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty else {
            // Try latin1 fallback
            return try? String(contentsOf: url, encoding: .isoLatin1)
        }
        return text
    }

    /// Detect file type from extension
    static func fileType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "pdf"
        case "md", "markdown": return "txt"
        default: return "txt"
        }
    }
}
