import Foundation
import Accelerate

/// Protocol for future PostgreSQL/pgvector extension
protocol VectorStoreProtocol {
    func search(query: [Float], topK: Int) async throws -> [VectorSearchResult]
}

struct VectorSearchResult {
    let chunkId: UUID
    let documentName: String
    let text: String
    let score: Float
}

/// On-device vector store using SwiftData + vDSP cosine similarity
final class VectorStore: VectorStoreProtocol {

    private var chunks: [DocumentChunk] = []

    func update(chunks: [DocumentChunk]) {
        self.chunks = chunks.filter { $0.hasEmbedding }
    }

    func search(query: [Float], topK: Int = 5) async throws -> [VectorSearchResult] {
        guard !chunks.isEmpty else { return [] }
        guard !query.isEmpty else { return [] }

        let results: [(DocumentChunk, Float)] = chunks.compactMap { chunk in
            let embedding = chunk.embedding
            guard embedding.count == query.count else { return nil }
            let sim = cosineSimilarity(a: query, b: embedding)
            return (chunk, sim)
        }

        return results
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { (chunk, score) in
                VectorSearchResult(
                    chunkId: chunk.id,
                    documentName: chunk.documentName,
                    text: chunk.text,
                    score: score
                )
            }
    }

    // MARK: - vDSP Cosine Similarity
    private func cosineSimilarity(a: [Float], b: [Float]) -> Float {
        let n = vDSP_Length(a.count)
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        vDSP_dotpr(a, 1, b, 1, &dotProduct, n)
        vDSP_svesq(a, 1, &normA, n)
        vDSP_svesq(b, 1, &normB, n)

        let denom = sqrt(normA) * sqrt(normB)
        guard denom > 0 else { return 0 }
        return dotProduct / denom
    }
}
