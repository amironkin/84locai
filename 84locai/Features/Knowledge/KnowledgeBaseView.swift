import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KnowledgeDocument.createdAt, order: .reverse) private var documents: [KnowledgeDocument]
    @Query private var allChunks: [DocumentChunk]

    var vm: KnowledgeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if vm.isIndexing {
                    indexingOverlay
                }

                Group {
                    if documents.isEmpty {
                        emptyState
                    } else {
                        documentList
                    }
                }
            }
            .navigationTitle("База знаний")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { vm.showImporter = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(LinearGradient.primaryGradient)
                    }
                }
            }
            .fileImporter(
                isPresented: $vm.showImporter,
                allowedContentTypes: [.pdf, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task { await vm.importDocument(url: url) }
                    }
                case .failure:
                    break
                }
            }
        }
    }

    // MARK: - Document List
    private var documentList: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                // Summary
                HStack {
                    Label("\(documents.count) документов", systemImage: "doc.text")
                    Spacer()
                    Label("\(allChunks.count) чанков", systemImage: "list.bullet")
                }
                .font(.appCaption)
                .foregroundStyle(.appTextMuted)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                ForEach(documents) { doc in
                    DocumentRowView(document: doc) {
                        vm.deleteDocument(doc, allChunks: allChunks)
                    }
                    .padding(.horizontal, Spacing.md)
                }

                Spacer(minLength: Spacing.xl)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 80, height: 80)
                    .blur(radius: 24)
                    .opacity(0.3)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            VStack(spacing: Spacing.xs) {
                Text("База знаний пуста")
                    .font(.appHeadline)
                    .foregroundStyle(.appTextPrimary)
                Text("Добавьте PDF или текстовые файлы\nдля работы с RAG")
                    .font(.appBody)
                    .foregroundStyle(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: { vm.showImporter = true }) {
                Label("Добавить документ", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .padding(Spacing.xl)
    }

    // MARK: - Indexing Overlay
    private var indexingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(true)

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.appPrimary)
                    .scaleEffect(1.5)

                VStack(spacing: Spacing.xs) {
                    Text("Индексация")
                        .font(.appHeadline)
                        .foregroundStyle(.appTextPrimary)
                    Text(vm.indexingDocumentName)
                        .font(.appCaption)
                        .foregroundStyle(.appTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(Spacing.xl)
            .glassCard()
        }
    }
}

// MARK: - Document Row
struct DocumentRowView: View {
    let document: KnowledgeDocument
    let onDelete: () -> Void
    @State private var showAlert = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // File icon
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(document.fileType == "pdf"
                          ? Color.appError.opacity(0.15)
                          : Color.appAccent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: document.fileIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(document.fileType == "pdf" ? Color.appError : Color.appAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(document.name)
                    .font(.appHeadline)
                    .foregroundStyle(.appTextPrimary)
                    .lineLimit(1)
                HStack(spacing: Spacing.sm) {
                    Text(document.fileSizeFormatted)
                    if document.isIndexed {
                        Text("· \(document.chunkCount) чанков")
                    } else {
                        Text("· Не проиндексирован")
                            .foregroundStyle(.appWarning)
                    }
                }
                .font(.appCaption)
                .foregroundStyle(.appTextMuted)
            }

            Spacer()

            // Indexed badge
            if document.isIndexed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.appSuccess)
            }

            Button(action: { showAlert = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.appError.opacity(0.7))
            }
        }
        .padding(Spacing.md)
        .glassCard()
        .alert("Удалить документ?", isPresented: $showAlert) {
            Button("Удалить", role: .destructive, action: onDelete)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Документ и все его чанки будут удалены из базы знаний")
        }
    }
}
