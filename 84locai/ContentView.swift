import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chunks: [DocumentChunk]

    @State private var llm = LLMEngine()
    @State private var embedder = EmbeddingEngine()
    @State private var selectedTab: Tab = .chat

    private var rag: RAGEngine { RAGEngine(embedder: embedder) }

    enum Tab: Int {
        case chat, models, knowledge
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Chat
            Tab("Чат", systemImage: "bubble.left.and.bubble.right.fill", value: .chat) {
                ChatView(
                    vm: ChatViewModel(llm: llm, rag: makeRAG(), modelContext: modelContext),
                    llm: llm
                )
            }

            // MARK: Models
            Tab("Модели", systemImage: "cpu.fill", value: .models) {
                ModelListView(llm: llm)
            }

            // MARK: Knowledge
            Tab("Знания", systemImage: "books.vertical.fill", value: .knowledge) {
                KnowledgeBaseView(
                    vm: KnowledgeViewModel(rag: makeRAG(), modelContext: modelContext)
                )
            }
        }
        .tint(.appPrimary)
        .preferredColorScheme(.dark)
        .onAppear {
            configureTabBarAppearance()
            // Preload chunks into vector store
            makeRAG().refreshStore(chunks: chunks)
        }
        .onChange(of: chunks.count) { _, _ in
            makeRAG().refreshStore(chunks: chunks)
        }
    }

    private func makeRAG() -> RAGEngine {
        let engine = RAGEngine(embedder: embedder)
        engine.refreshStore(chunks: chunks)
        return engine
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appSurface)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.appTextMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.appTextMuted)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.appPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.appPrimary)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
