import Foundation
import SwiftData
import MLXLMCommon

@Observable
@MainActor
final class ChatViewModel {

    var currentSession: ChatSession?
    var inputText: String = ""
    var isGenerating: Bool = false
    var ragEnabled: Bool = false
    var errorMessage: String?

    private let llm: LLMEngine
    private let rag: RAGEngine
    private var modelContext: SwiftData.ModelContext

    init(llm: LLMEngine, rag: RAGEngine, modelContext: SwiftData.ModelContext) {
        self.llm = llm
        self.rag = rag
        self.modelContext = modelContext
    }

    // MARK: - Session Management
    func createSession(title: String = "New Chat") -> ChatSession {
        let session = ChatSession(title: title, modelId: llm.activeModelId ?? "")
        modelContext.insert(session)
        try? modelContext.save()
        currentSession = session
        return session
    }

    func deleteSession(_ session: ChatSession) {
        if currentSession?.id == session.id { currentSession = nil }
        modelContext.delete(session)
        try? modelContext.save()
    }

    // MARK: - Send Message
    func send() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard llm.isReady else {
            errorMessage = "Сначала выберите и загрузите модель"
            return
        }

        let session = currentSession ?? createSession()
        let userText = inputText
        inputText = ""
        isGenerating = true
        errorMessage = nil

        // 1. Add user message
        let userMsg = ChatMessage(role: "user", content: userText)
        session.messages.append(userMsg)
        session.updatedAt = Date()

        // 2. Optionally retrieve RAG context
        var ragContext = ""
        if ragEnabled {
            ragContext = (try? await rag.retrieve(query: userText)) ?? ""
        }

        // 3. Build messages array for LLM
        var messages: [Message] = []

        if !ragContext.isEmpty {
            let systemContent: String = """
                Ты полезный ассистент. Используй следующий контекст из базы знаний для ответа на вопрос пользователя.
                Если контекст не релевантен, отвечай по своим знаниям.

                КОНТЕКСТ:
                \(ragContext)
                """
            messages.append(["role": "system", "content": systemContent])
        } else {
            messages.append(["role": "system", "content": "Ты полезный ассистент."])
        }

        // Add conversation history (last 10 messages)
        let history = session.sortedMessages.suffix(10).dropLast() // exclude the one just added
        for msg in history {
            messages.append(["role": msg.role, "content": msg.content])
        }
        messages.append(["role": "user", "content": userText])

        // 4. Stream assistant response
        let assistantMsg = ChatMessage(role: "assistant", content: "")
        assistantMsg.isStreaming = true
        session.messages.append(assistantMsg)

        do {
            try await llm.generate(messages: messages) { token in
                Task { @MainActor in
                    assistantMsg.content += token
                }
            }
        } catch {
            assistantMsg.content = "Ошибка: \(error.localizedDescription)"
        }

        assistantMsg.isStreaming = false

        // Auto-title session from first user message
        if session.title == "New Chat" {
            session.title = String(userText.prefix(40))
        }
        session.updatedAt = Date()
        try? modelContext.save()
        isGenerating = false
    }

    func clearSession() {
        guard let session = currentSession else { return }
        for msg in session.messages { modelContext.delete(msg) }
        session.messages.removeAll()
        try? modelContext.save()
    }
}
