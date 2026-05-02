import SwiftUI

struct ModelListView: View {
    var llm: LLMEngine
    @State private var modelManager = ModelManager()
    @State private var loadingModelId: String?

    private var usedGB: String {
        String(format: "%.1f GB", modelManager.totalUsedGB)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // LLM Status Card
                        statusCard
                            .padding(.horizontal, Spacing.md)

                        // Disk usage
                        HStack {
                            Text("Используется: \(usedGB)")
                                .font(.appCaption)
                                .foregroundStyle(.appTextMuted)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.md)

                        // Model list
                        ForEach(ModelInfo.catalog) { model in
                            ModelCardView(
                                model: model,
                                isActive: llm.activeModelId == model.id,
                                isDownloaded: modelManager.isDownloaded(model),
                                downloadProgress: loadingModelId == model.id
                                    ? progressValue(for: llm.state) : nil,
                                onLoad: { Task { await loadModel(model) } },
                                onDelete: { modelManager.deleteModel(model) }
                            )
                            .padding(.horizontal, Spacing.md)
                        }

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Модели")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                modelManager.scanDownloadedModels()
            }
        }
    }

    // MARK: - Status Card
    private var statusCard: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusGradient)
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.appHeadline)
                    .foregroundStyle(.appTextPrimary)
                Text(statusSubtitle)
                    .font(.appCaption)
                    .foregroundStyle(.appTextSecondary)
            }

            Spacer()

            if case .downloading(let p) = llm.state {
                ProgressRing(progress: p, size: 40)
            }
        }
        .padding(Spacing.md)
        .glassCard()
    }

    // MARK: - Helpers
    private func loadModel(_ model: ModelInfo) async {
        loadingModelId = model.id
        do {
            try await llm.load(model: model)
            modelManager.scanDownloadedModels()
        } catch {
            // error shown in llm.state
        }
        loadingModelId = nil
    }

    private func progressValue(for state: LLMEngine.State) -> Double {
        if case .downloading(let p) = state { return p }
        return 0
    }

    private var statusIcon: String {
        switch llm.state {
        case .ready: return "checkmark"
        case .downloading, .loading: return "arrow.down"
        case .generating: return "waveform"
        case .error: return "exclamationmark"
        default: return "cpu"
        }
    }

    private var statusGradient: LinearGradient {
        switch llm.state {
        case .ready: return LinearGradient(colors: [.appSuccess, .appAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .error: return LinearGradient(colors: [.appError, .appWarning], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return .primaryGradient
        }
    }

    private var statusTitle: String {
        switch llm.state {
        case .idle: return "Модель не выбрана"
        case .downloading: return "Загрузка..."
        case .loading: return "Инициализация..."
        case .ready(let id):
            return ModelInfo.catalog.first(where: { $0.id == id })?.displayName ?? "Модель готова"
        case .generating: return "Генерация..."
        case .error(let msg): return "Ошибка"
        }
    }

    private var statusSubtitle: String {
        switch llm.state {
        case .idle: return "Выберите модель ниже"
        case .downloading(let p): return "\(Int(p * 100))% — не закрывайте приложение"
        case .loading: return "Загрузка весов в память..."
        case .ready: return "Готова к работе"
        case .generating: return "Обработка запроса..."
        case .error(let msg): return msg
        }
    }
}
