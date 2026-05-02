import SwiftUI

struct ModelCardView: View {
    let model: ModelInfo
    let isActive: Bool
    let isDownloaded: Bool
    let downloadProgress: Double?
    let onLoad: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteAlert = false

    private var statusColor: Color {
        if isActive { return .appSuccess }
        if isDownloaded { return .appAccent }
        return .appTextMuted
    }

    private var statusLabel: String {
        if isActive { return "Активна" }
        if downloadProgress != nil { return "Загрузка..." }
        if isDownloaded { return "Загружена" }
        return String(format: "%.1f GB", model.sizeGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                // Category badge
                Text(model.category)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.appAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.appAccent.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .opacity(isActive ? 1 : 0.6)
                    Text(statusLabel)
                        .font(.appCaption)
                        .foregroundStyle(statusColor)
                }
            }

            Text(model.displayName)
                .font(.appHeadline)
                .foregroundStyle(.appTextPrimary)

            Text(model.description)
                .font(.appBody)
                .foregroundStyle(.appTextSecondary)
                .lineLimit(2)

            // Download progress
            if let prog = downloadProgress {
                DownloadProgressBar(progress: prog, label: "Загрузка модели")
                    .padding(.top, Spacing.xs)
            }

            // Action buttons
            HStack(spacing: Spacing.sm) {
                if !isActive {
                    Button(action: onLoad) {
                        Label(isDownloaded ? "Активировать" : "Загрузить", 
                              systemImage: isDownloaded ? "play.fill" : "arrow.down.circle.fill")
                            .font(.appCaption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule().fill(LinearGradient.primaryGradient)
                            )
                    }
                } else {
                    Label("Активна", systemImage: "checkmark.circle.fill")
                        .font(.appCaption)
                        .foregroundStyle(.appSuccess)
                }

                Spacer()

                if isDownloaded && !isActive {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.appError)
                    }
                }
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
        .glassCard()
        .alert("Удалить модель?", isPresented: $showDeleteAlert) {
            Button("Удалить", role: .destructive, action: onDelete)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("\(model.displayName) будет удалена с устройства")
        }
    }
}
