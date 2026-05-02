import Foundation
import SwiftData

@Observable
@MainActor
final class KnowledgeViewModel {

    var isIndexing: Bool = false
    var indexingProgress: Double = 0
    var indexingDocumentName: String = ""
    var errorMessage: String?
    var showImporter: Bool = false

    private let rag: RAGEngine
    private var modelContext: SwiftData.ModelContext

    init(rag: RAGEngine, modelContext: SwiftData.ModelContext) {
        self.rag = rag
        self.modelContext = modelContext
    }

    // MARK: - Import Document
    func importDocument(url: URL) async {
        isIndexing = true
        indexingProgress = 0
        errorMessage = nil
        indexingDocumentName = url.lastPathComponent

        // Security scoped access
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        // Parse text
        let fileType = TextParser.fileType(for: url)
        let rawText: String?
        if fileType == "pdf" {
            rawText = PDFParser.parse(url: url)
        } else {
            rawText = TextParser.parse(url: url)
        }

        guard let text = rawText, !text.isEmpty else {
            errorMessage = "Не удалось прочитать файл или файл пуст"
            isIndexing = false
            return
        }

        // Get file size
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0

        // Create document record
        let doc = KnowledgeDocument(
            name: url.lastPathComponent,
            fileType: fileType,
            fileSize: Int64(fileSize)
        )
        modelContext.insert(doc)

        // Index
        do {
            indexingProgress = 0.1
            try await rag.indexDocument(doc, rawText: text, context: modelContext)
            indexingProgress = 1.0
        } catch {
            errorMessage = "Ошибка индексации: \(error.localizedDescription)"
            modelContext.delete(doc)
            try? modelContext.save()
        }

        isIndexing = false
        indexingDocumentName = ""
    }

    // MARK: - Delete Document
    func deleteDocument(_ doc: KnowledgeDocument, allChunks: [DocumentChunk]) {
        // Remove all associated chunks
        let docChunks = allChunks.filter { $0.documentId == doc.id }
        for chunk in docChunks { modelContext.delete(chunk) }
        modelContext.delete(doc)
        try? modelContext.save()

        // Refresh vector store with remaining chunks
        let remaining = allChunks.filter { $0.documentId != doc.id }
        rag.refreshStore(chunks: remaining)
    }
}
