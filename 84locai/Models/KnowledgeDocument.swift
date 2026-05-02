import Foundation
import SwiftData

@Model
final class KnowledgeDocument {
    var id: UUID
    var name: String
    var fileType: String // "pdf" | "txt"
    var fileSize: Int64
    var createdAt: Date
    var isIndexed: Bool
    var chunkCount: Int
    @Relationship(deleteRule: .cascade) var chunks: [DocumentChunk]

    init(name: String, fileType: String, fileSize: Int64 = 0) {
        self.id = UUID()
        self.name = name
        self.fileType = fileType
        self.fileSize = fileSize
        self.createdAt = Date()
        self.isIndexed = false
        self.chunkCount = 0
        self.chunks = []
    }

    var fileSizeFormatted: String {
        let mb = Double(fileSize) / 1_048_576
        return mb < 1 ? String(format: "%.0f KB", mb * 1024) : String(format: "%.1f MB", mb)
    }

    var fileIcon: String {
        fileType == "pdf" ? "doc.richtext" : "doc.text"
    }
}
