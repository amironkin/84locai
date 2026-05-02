import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.updatedAt, order: .reverse) private var sessions: [ChatSession]

    var vm: ChatViewModel
    var llm: LLMEngine

    @State private var showSidebar = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: Header
                    chatHeader

                    Divider().overlay(Color.appBorder)

                    // MARK: Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Spacing.sm) {
                                if vm.currentSession?.sortedMessages.isEmpty ?? true {
                                    emptyState
                                }
                                ForEach(vm.currentSession?.sortedMessages ?? []) { msg in
                                    MessageBubble(message: msg)
                                        .id(msg.id)
                                }
                                if vm.isGenerating,
                                   vm.currentSession?.sortedMessages.last?.isStreaming == false {
                                    HStack {
                                        TypingIndicator()
                                            .padding(.leading, Spacing.md + 38)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.md)
                        }
                        .onChange(of: vm.currentSession?.messages.count) { _, _ in
                            if let lastId = vm.currentSession?.sortedMessages.last?.id {
                                withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                            }
                        }
                    }

                    // MARK: Error
                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.appCaption)
                            .foregroundStyle(.appError)
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xs)
                    }

                    Divider().overlay(Color.appBorder)

                    // MARK: Input Bar
                    inputBar
                }
            }
        }
        .sheet(isPresented: $showSidebar) {
            ChatHistorySheet(sessions: sessions, vm: vm)
        }
    }

    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: { showSidebar.toggle() }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 18))
                    .foregroundStyle(.appTextSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(vm.currentSession?.title ?? "84locai")
                    .font(.appHeadline)
                    .foregroundStyle(.appTextPrimary)
                    .lineLimit(1)
                if let modelId = llm.activeModelId,
                   let model = ModelInfo.catalog.first(where: { $0.id == modelId }) {
                    Text(model.displayName)
                        .font(.appCaption)
                        .foregroundStyle(.appAccent)
                }
            }

            Spacer()

            Button(action: { vm.createSession() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18))
                    .foregroundStyle(.appTextSecondary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            // RAG toggle
            Button(action: { vm.ragEnabled.toggle() }) {
                Image(systemName: vm.ragEnabled ? "books.vertical.fill" : "books.vertical")
                    .font(.system(size: 18))
                    .foregroundStyle(vm.ragEnabled ? .appAccent : .appTextMuted)
                    .animation(.spring(response: 0.3), value: vm.ragEnabled)
            }
            .frame(width: 36, height: 36)

            // Text input
            TextField("Сообщение...", text: $vm.inputText, axis: .vertical)
                .font(.appBody)
                .foregroundStyle(.appTextPrimary)
                .tint(.appPrimary)
                .focused($inputFocused)
                .lineLimit(1...5)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(Color.appCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.xl)
                                .stroke(inputFocused ? Color.appPrimary.opacity(0.6) : Color.appBorder, lineWidth: 1)
                        )
                )
                .onSubmit {
                    guard !vm.isGenerating else { return }
                    Task { await vm.send() }
                }

            // Send / Stop button
            Button(action: {
                inputFocused = false
                Task { await vm.send() }
            }) {
                ZStack {
                    Circle()
                        .fill(vm.inputText.isEmpty ? Color.appCard : LinearGradient.primaryGradient as AnyShapeStyle)
                        .frame(width: 36, height: 36)
                    Image(systemName: vm.isGenerating ? "stop.fill" : "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(vm.inputText.isEmpty ? Color.appTextMuted : .white)
                }
            }
            .disabled(vm.inputText.isEmpty && !vm.isGenerating)
            .animation(.spring(response: 0.3), value: vm.inputText.isEmpty)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: 80)
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 72, height: 72)
                    .blur(radius: 20)
                    .opacity(0.4)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            VStack(spacing: Spacing.xs) {
                Text("84locai")
                    .font(.appTitle)
                    .foregroundStyle(.appTextPrimary)
                Text("Локальный AI прямо на вашем iPhone")
                    .font(.appBody)
                    .foregroundStyle(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if !llm.isReady {
                NavigationLink(destination: Text("")) {
                    Label("Выбрать модель", systemImage: "cpu")
                        .font(.appHeadline)
                        .foregroundStyle(.appPrimary)
                }
            }
            Spacer(minLength: 40)
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Chat History Sheet
struct ChatHistorySheet: View {
    let sessions: [ChatSession]
    var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                List {
                    ForEach(sessions) { session in
                        Button(action: {
                            vm.currentSession = session
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(session.title)
                                        .font(.appHeadline)
                                        .foregroundStyle(.appTextPrimary)
                                        .lineLimit(1)
                                    Text(session.updatedAt.formatted(.relative(presentation: .named)))
                                        .font(.appCaption)
                                        .foregroundStyle(.appTextMuted)
                                }
                                Spacer()
                                if vm.currentSession?.id == session.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.appPrimary)
                                }
                            }
                        }
                        .listRowBackground(Color.appCard)
                    }
                    .onDelete { offsets in
                        for i in offsets { vm.deleteSession(sessions[i]) }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("История чатов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(.appPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        vm.createSession()
                        dismiss()
                    }) {
                        Label("Новый чат", systemImage: "square.and.pencil")
                            .foregroundStyle(.appPrimary)
                    }
                }
            }
        }
    }
}
