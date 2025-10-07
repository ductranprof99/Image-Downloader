
class FullFeaturedViewModel: ObservableObject {
    @Published var imageItems: [ImageItem] = []
    @Published var cacheCount: Int = 0
    @Published var storageSizeString: String = "0 MB"
    @Published var activeDownloads: Int = 0

    private let manager = ImageDownloaderManager.shared
    private var refreshTimer: Timer?

    init() {
        startRefreshTimer()
    }

    func loadImages() {
        imageItems = ImageItem.generateSampleData(count: 30)
        refreshStats()
    }

    func refreshStats() {
        let highCache = manager.cacheSizeHigh()
        let lowCache = manager.cacheSizeLow()
        cacheCount = highCache + lowCache

        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        storageSizeString = String(format: "%.1f MB", mb)

        activeDownloads = manager.activeDownloadsCount()
    }

    func clearCache() {
        manager.clearAllCache()
        refreshStats()
    }

    func clearStorage() {
        manager.clearStorage { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshStats()
            }
        }
    }

    func clearAll() {
        manager.hardReset()
        refreshStats()
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshStats()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
