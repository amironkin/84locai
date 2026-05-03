import Foundation
import MLXLLM
import MLXLMCommon
import MLX

// MARK: - Available Models Catalog
struct ModelInfo: Identifiable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let sizeGB: Double
    let category: String

    var configuration: ModelConfiguration {
        ModelConfiguration(id: id)
    }

    static let catalog: [ModelInfo] = [
        ModelInfo(
            id: "mlx-community/Qwen2.5-3B-Instruct-4bit",
            displayName: "Qwen 2.5 · 3B",
            description: "Быстрая и умная модель. Лучший баланс скорости и качества.",
            sizeGB: 1.9,
            category: "Balanced"
        ),
        ModelInfo(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            displayName: "Llama 3.2 · 3B",
            description: "Meta's последняя модель. Отличная для диалога.",
            sizeGB: 1.8,
            category: "Chat"
        ),
        ModelInfo(
            id: "mlx-community/Phi-3.5-mini-instruct-4bit",
            displayName: "Phi 3.5 Mini",
            description: "Microsoft. Высокое качество в компактном размере.",
            sizeGB: 2.2,
            category: "Quality"
        ),
        ModelInfo(
            id: "mlx-community/gemma-3-4b-it-4bit",
            displayName: "Gemma 3 · 4B",
            description: "Google Gemma 3. Мощная модель для сложных задач.",
            sizeGB: 2.5,
            category: "Quality"
        ),
        ModelInfo(
            id: "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
            displayName: "Mistral 7B",
            description: "Флагман Mistral AI. Максимальное качество ответов.",
            sizeGB: 4.1,
            category: "Powerful"
        ),
    ]
}

// MARK: - LLM Errors
enum LLMError: LocalizedError {
    case modelNotLoaded
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Модель не загружена"
        case .generationFailed(let msg): return "Ошибка генерации: \(msg)"
        }
    }
}

// MARK: - LLM Engine
@Observable
@MainActor
final class LLMEngine {

    enum State: Equatable {
        case idle
        case downloading(progress: Double)
        case loading
        case ready(modelId: String)
        case generating
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.generating, .generating): return true
            case (.downloading(let a), .downloading(let b)): return a == b
            case (.ready(let a), .ready(let b)): return a == b
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    var state: State = .idle
    var activeModelId: String?
    private var container: ModelContainer?

    // MARK: Load Model
    func load(model: ModelInfo) async throws {
        state = .downloading(progress: 0)
        activeModelId = model.id

        do {
            container = try await LLMModelFactory.shared.loadContainer(
                configuration: model.configuration
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.state = .downloading(progress: progress.fractionCompleted)
                }
            }
            state = .ready(modelId: model.id)
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    func unload() {
        container = nil
        state = .idle
        activeModelId = nil
    }

    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    // MARK: Generate (streaming)
    /// Generates text token by token calling `onToken` for each chunk.
    func generate(
        messages: [Message],
        temperature: Float = 0.7,
        onToken: @escaping @Sendable (String) -> Void
    ) async throws {
        guard let container else { throw LLMError.modelNotLoaded }
        state = .generating
        defer {
            if case .generating = state {
                state = .ready(modelId: activeModelId ?? "")
            }
        }

        // Prepare input using UserInput with the messages array
        let userInput = UserInput(messages: messages)
        let lmInput = try await container.prepare(input: userInput)

        let parameters = GenerateParameters(temperature: temperature)
        let stream = try await container.generate(input: lmInput, parameters: parameters)

        for await generation in stream {
            switch generation {
            case .chunk(let text):
                onToken(text)
            case .info:
                break
            case .toolCall:
                break
            }
        }
    }
}
