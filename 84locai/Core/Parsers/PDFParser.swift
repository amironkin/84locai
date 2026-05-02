import Foundation
import PDFKit

struct PDFParser {

    /// Extract all text from a PDF file URL
    static func parse(url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var fullText = ""

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            if let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }

        return fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : fullText
    }

    static func pageCount(url: URL) -> Int {
        PDFDocument(url: url)?.pageCount ?? 0
    }
}
