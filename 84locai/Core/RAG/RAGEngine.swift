import Foundation
import SwiftData

@MainActor
final class RAGEngine {

    private let embedder: EmbeddingEngine
    private let vectorStore: VectorStore
    private let chunker = TextChunker(chunkSize: 512, overlap: 64)

    init(embedder: EmbeddingEngine) {
        self.embedder = embedder
        self.vectorStore = VectorStore()
    }

    // MARK: - Index Document
    func indexDocument(
        _ document: KnowledgeDocument,
        rawText: String,
        context: SwiftData.ModelContext
    ) async throws {
        // 1. Split into chunks
        let textChunks = chunker.split(rawText)
        guard !textChunks.isEmpty else { return }

        // 2. Ensure embedder is loaded
        if !embedder.isLoaded {
            try await embedder.load()
        }

        // 3. Compute embeddings in batches of 8
        let batchSize = 8
        var chunks: [DocumentChunk] = []

        for batchStart in stride(from: 0, to: textChunks.count, by: batchSize) {
            let end = min(batchStart + batchSize, textChunks.count)
            let batch = Array(textChunks[batchStart..<end])
            let embeddings = try await embedder.encode(batch)

            for (i, (text, embedding)) in zip(batch, embeddings).enumerated() {
                let chunk = DocumentChunk(
                    documentId: document.id,
                    documentName: document.name,
                    text: text,
                    chunkIndex: batchStart + i
                )
                chunk.embedding = embedding
                context.insert(chunk)
                chunks.append(chunk)
            }
        }

        // 4. Mark document as indexed
        document.isIndexed = true
        document.chunkCount = chunks.count
        try context.save()

        // 5. Refresh vector store
        refreshStore(chunks: getAllChunks(context: context))
    }

    // MARK: - Retrieve Context
    func retrieve(query: String, topK: Int = 5) async throws -> String {
        guard embedder.isLoaded else { return "" }

        let queryEmbedding = try await embedder.encode(query)
        let results = try await vectorStore.search(query: queryEmbedding, topK: topK)

        guard !results.isEmpty else { return "" }

        let contextBlocks = results.enumerated().map { (i, r) in
            "[\(i + 1)] \(r.documentName)\n\(r.text)"
        }

        return contextBlocks.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Refresh Store from SwiftData
    func refreshStore(chunks: [DocumentChunk]) {
        vectorStore.update(chunks: chunks)
    }

    private func getAllChunks(context: SwiftData.ModelContext) -> [DocumentChunk] {
        let descriptor = FetchDescriptor<DocumentChunk>()
        return (try? context.fetch(descriptor)) ?? []
    }
}
