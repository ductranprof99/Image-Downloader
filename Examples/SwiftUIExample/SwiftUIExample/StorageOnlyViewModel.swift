class StorageOnlyViewModel: ObservableObject {
    @Published var storedImages: [URL] = []
    @Published var storedImageCount: Int = 0
    @Published var storageSizeString: String = "0 MB"

    private let manager = ImageDownloaderManager.shared

    func loadStorageInfo() {
        // Get storage size
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        storageSizeString = String(format: "%.2f MB", mb)

        // For demo purposes, we'll use sample URLs
        // In production, you'd track which URLs are actually stored
        storedImages = ImageItem.generateSampleData(count: 20).map { $0.url }
        storedImageCount = storedImages.count
    }

    func refreshStorageInfo() {
        loadStorageInfo()
    }

    func clearStorage() {
        manager.clearStorage { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.storedImages = []
                    self?.storedImageCount = 0
                    self?.storageSizeString = "0 MB"
                }
            }
        }
    }
}