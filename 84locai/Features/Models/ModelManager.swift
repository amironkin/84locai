import Foundation

@Observable
@MainActor
final class ModelManager {

    var downloadedModelIds: Set<String> = []
    var downloadProgress: [String: Double] = [:]

    private let modelsDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        modelsDirectory = docs.appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        scanDownloadedModels()
    }

    // MARK: - Disk Scan
    func scanDownloadedModels() {
        // MLX Swift caches models in Library/Caches/huggingface/hub/
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/hub")

        downloadedModelIds = []

        for model in ModelInfo.catalog {
            // HuggingFace hub cache dir: models--{org}--{name}
            let dirName = "models--" + model.id.replacingOccurrences(of: "/", with: "--")
            let modelDir = cacheDir.appendingPathComponent(dirName)
            if FileManager.default.fileExists(atPath: modelDir.path) {
                downloadedModelIds.insert(model.id)
            }
        }
    }

    func isDownloaded(_ model: ModelInfo) -> Bool {
        downloadedModelIds.contains(model.id)
    }

    // MARK: - Delete Model
    func deleteModel(_ model: ModelInfo) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/hub")
        let dirName = "models--" + model.id.replacingOccurrences(of: "/", with: "--")
        let modelDir = cacheDir.appendingPathComponent(dirName)
        try? FileManager.default.removeItem(at: modelDir)
        downloadedModelIds.remove(model.id)
    }

    // MARK: - Disk Usage
    var totalUsedGB: Double {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/hub")
        return dirSize(cacheDir) / 1_073_741_824
    }

    private func dirSize(_ url: URL) -> Double {
        guard let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return Double(total)
    }
}
