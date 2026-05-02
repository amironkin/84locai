import Foundation
import SwiftData

@Model
final class DocumentChunk {
    var id: UUID
    var documentId: UUID
    var documentName: String
    var text: String
    var embeddingData: Data // serialized [Float]
    var chunkIndex: Int
    var createdAt: Date

    init(documentId: UUID, documentName: String, text: String, chunkIndex: Int) {
        self.id = UUID()
        self.documentId = documentId
        self.documentName = documentName
        self.text = text
        self.embeddingData = Data()
        self.chunkIndex = chunkIndex
        self.createdAt = Date()
    }

    /// Embedding vector as [Float]
    var embedding: [Float] {
        get {
            embeddingData.withUnsafeBytes { ptr in
                guard ptr.count > 0 else { return [] }
                return Array(ptr.bindMemory(to: Float.self))
            }
        }
        set {
            embeddingData = newValue.withUnsafeBytes { Data($0) }
        }
    }

    var hasEmbedding: Bool { !embeddingData.isEmpty }
}
