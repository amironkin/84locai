import Foundation

/// Splits text into overlapping chunks for RAG indexing
struct TextChunker {
    let chunkSize: Int
    let overlap: Int

    init(chunkSize: Int = 512, overlap: Int = 64) {
        self.chunkSize = chunkSize
        self.overlap = overlap
    }

    func split(_ text: String) -> [String] {
        let cleaned = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Split by paragraphs first
        let paragraphs = cleaned.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var chunks: [String] = []
        var currentChunk = ""

        for paragraph in paragraphs {
            let words = paragraph.components(separatedBy: .whitespaces)

            for word in words {
                let candidate = currentChunk.isEmpty ? word : "\(currentChunk) \(word)"
                if candidate.count <= chunkSize {
                    currentChunk = candidate
                } else {
                    if !currentChunk.isEmpty {
                        chunks.append(currentChunk)
                        // carry overlap from the end
                        let overlapText = overlapTail(of: currentChunk)
                        currentChunk = overlapText.isEmpty ? word : "\(overlapText) \(word)"
                    } else {
                        currentChunk = word
                    }
                }
            }

            // Paragraph boundary — flush if chunk is getting long
            if currentChunk.count >= chunkSize / 2 {
                chunks.append(currentChunk)
                currentChunk = ""
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks
    }

    private func overlapTail(of text: String) -> String {
        let words = text.components(separatedBy: .whitespaces)
        var tail = ""
        for word in words.reversed() {
            let candidate = tail.isEmpty ? word : "\(word) \(tail)"
            if candidate.count <= overlap { tail = candidate } else { break }
        }
        return tail
    }
}
