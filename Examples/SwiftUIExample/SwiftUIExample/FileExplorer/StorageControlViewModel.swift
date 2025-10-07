class StorageControlViewModel: ObservableObject {
    @Published var compressionInfo: String = "PNG"
    @Published var pathProviderInfo: String = "Flat"
    @Published var examplePath: String = ""
    @Published var storageSizeString: String = "0 MB"
    @Published var fileCount: Int = 0
    @Published var storagePathShort: String = ""
    @Published var fileList: [StorageFileInfo] = []

    private let manager = ImageDownloaderManager.shared
    private var currentCompressionProvider: ImageCompressionProvider = PNGCompressionProvider()
    private var currentPathProvider: StoragePathProvider = FlatHierarchicalPathProvider()

    func loadInfo() {
        updateCompressionInfo()
        updatePathProviderInfo()
        updateExamplePath()
        refreshStats()
    }

    func updateCompression(_ type: CompressionType, quality: Double) {
        switch type {
        case .png:
            currentCompressionProvider = PNGCompressionProvider()
        case .jpeg:
            currentCompressionProvider = JPEGCompressionProvider(quality: quality)
        case .adaptive:
            currentCompressionProvider = AdaptiveCompressionProvider(sizeThresholdMB: 1.0, jpegQuality: quality)
        }
        updateCompressionInfo()
        updateExamplePath()
    }

    func updatePathProvider(_ type: PathProviderType) {
        switch type {
        case .flat:
            currentPathProvider = FlatHierarchicalPathProvider()
        case .domain:
            currentPathProvider = DomainHierarchicalPathProvider()
        case .date:
            currentPathProvider = DateHierarchicalPathProvider()
        }
        updatePathProviderInfo()
        updateExamplePath()
    }

    func refreshStats() {
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        storageSizeString = String(format: "%.2f MB", mb)

        // Get storage path (simplified - use cache directory)
        if let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let storageURL = cachesDir.appendingPathComponent("ImageDownloaderStorage")
            storagePathShort = storageURL.lastPathComponent
        }

        // Count files (simplified)
        if let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let storageURL = cachesDir.appendingPathComponent("ImageDownloaderStorage")
            if let files = try? FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil) {
                fileCount = files.count

                // Get file list with info
                fileList = files.compactMap { url in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let size = attributes[.size] as? UInt64,
                          let modificationDate = attributes[.modificationDate] as? Date else {
                        return nil
                    }
                    return StorageFileInfo(
                        name: url.lastPathComponent,
                        path: url.path,
                        size: size,
                        modificationDate: modificationDate
                    )
                }
                .sorted { $0.modificationDate > $1.modificationDate }
            } else {
                fileCount = 0
                fileList = []
            }
        }
    }

    func clearAllStorage() {
        manager.clearStorage { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.refreshStats()
                }
            }
        }
    }

    private func updateCompressionInfo() {
        compressionInfo = currentCompressionProvider.name
    }

    private func updatePathProviderInfo() {
        switch currentPathProvider {
        case is FlatHierarchicalPathProvider:
            pathProviderInfo = "Flat"
        case is DomainHierarchicalPathProvider:
            pathProviderInfo = "Domain Hierarchical"
        case is DateHierarchicalPathProvider:
            pathProviderInfo = "Date Hierarchical"
        default:
            pathProviderInfo = "Custom"
        }
    }

    private func updateExamplePath() {
        let exampleURL = URL(string: "https://picsum.photos/id/237/200/300.jpg")!
        let identifier = MD5IdentifierProvider().identifier(for: exampleURL)
        let path = currentPathProvider.path(for: exampleURL, identifier: identifier)
        examplePath = path
    }
}
