import Foundation
import MLX
import MLXEmbedders
import MLXLMCommon

enum EmbedderError: LocalizedError {
    case notLoaded
    case encodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notLoaded: return "Эмбеддер не загружен"
        case .encodingFailed(let msg): return "Ошибка эмбеддинга: \(msg)"
        }
    }
}

@Observable
@MainActor
final class EmbeddingEngine {

    var isLoaded = false
    private var container: EmbedderModelContainer?

    // multilingual-e5-small: supports Russian, compact (~90MB)
    private let modelConfig = EmbedderRegistry.multilingual_e5_small

    func load() async throws {
        container = try await EmbedderModelFactory.shared.loadContainer(
            from: EmbedderModelFactory.shared.downloader,
            using: EmbedderModelFactory.shared.tokenizerLoader,
            configuration: modelConfig,
            useLatest: false
        )
        isLoaded = true
    }

    /// Encode a list of texts → [[Float]] embeddings
    func encode(_ texts: [String]) async throws -> [[Float]] {
        guard let container else { throw EmbedderError.notLoaded }
        guard !texts.isEmpty else { return [] }

        return try await container.perform { context in
            // Tokenize each input
            let tokenizer = context.tokenizer

            var inputIds: [[Int]] = []
            var tokenTypesAll: [[Int]] = []

            for text in texts {
                let tokens = tokenizer.encode(text: text, addSpecialTokens: true)
                inputIds.append(tokens)
                tokenTypesAll.append(Array(repeating: 0, count: tokens.count))
            }

            // Pad to max length
            let maxLen = inputIds.map(\.count).max() ?? 0
            var paddedIds: [[Int32]] = []
            var attentionMasks: [[Int32]] = []
            var tokenTypes: [[Int32]] = []

            for (ids, types) in zip(inputIds, tokenTypesAll) {
                let padLen = maxLen - ids.count
                paddedIds.append(ids.map { Int32($0) } + Array(repeating: Int32(0), count: padLen))
                attentionMasks.append(Array(repeating: Int32(1), count: ids.count) + Array(repeating: Int32(0), count: padLen))
                tokenTypes.append(types.map { Int32($0) } + Array(repeating: Int32(0), count: padLen))
            }

            let batchSize = texts.count
            let inputArray  = MLXArray(paddedIds.flatMap { $0 }, [batchSize, maxLen])
            let maskArray   = MLXArray(attentionMasks.flatMap { $0 }, [batchSize, maxLen])
            let typesArray  = MLXArray(tokenTypes.flatMap { $0 }, [batchSize, maxLen])

            // Forward pass
            let output = context.model(
                inputArray,
                positionIds: nil,
                tokenTypeIds: typesArray,
                attentionMask: maskArray
            )

            // Pool + normalize
            let boolMask = maskArray .== MLXArray(Int32(1))
            let pooled = context.pooling(output, mask: boolMask, normalize: true, applyLayerNorm: false)
            pooled.eval()

            // Convert MLXArray [batchSize x dims] → [[Float]]
            let flat = pooled.asArray(Float.self)
            let dims = pooled.shape[1]
            var result: [[Float]] = []
            for i in 0..<batchSize {
                let start = i * dims
                result.append(Array(flat[start ..< start + dims]))
            }
            return result
        }
    }

    /// Encode a single text → [Float]
    func encode(_ text: String) async throws -> [Float] {
        let results = try await encode([text])
        guard let first = results.first else {
            throw EmbedderError.encodingFailed("Empty result")
        }
        return first
    }
}
