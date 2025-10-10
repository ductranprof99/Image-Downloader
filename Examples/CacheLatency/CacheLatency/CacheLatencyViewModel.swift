//
//  CacheLatencyViewModel.swift
//  CacheLatency
//
//  Demonstrates high/low latency cache behavior
//

import SwiftUI
import ImageDownloader

final class CacheLatencyViewModel: ObservableObject {
    // Cache config
    @Published var highLatencyLimit: Int = 10
    @Published var lowLatencyLimit: Int = 20

    // Test state
    @Published var isLoading: Bool = false
    @Published var highLatencyImages: [String: UIImage] = [:]
    @Published var lowLatencyImages: [String: UIImage] = [:]
    @Published var cacheStats: CacheStats?

    private var customConfig: IDConfiguration?

    // Image URLs for testing
    let imageURLs = [
        "https://picsum.photos/id/1/400/400",
        "https://picsum.photos/id/10/400/400",
        "https://picsum.photos/id/100/400/400",
        "https://picsum.photos/id/1000/400/400",
        "https://picsum.photos/id/1001/400/400",
        "https://picsum.photos/id/1002/400/400",
        "https://picsum.photos/id/1003/400/400",
        "https://picsum.photos/id/1004/400/400",
        "https://picsum.photos/id/1005/400/400",
        "https://picsum.photos/id/1006/400/400",
        "https://picsum.photos/id/1008/400/400",
        "https://picsum.photos/id/1009/400/400",
        "https://picsum.photos/id/101/400/400",
        "https://picsum.photos/id/1010/400/400",
        "https://picsum.photos/id/1011/400/400",
        "https://picsum.photos/id/1012/400/400",
        "https://picsum.photos/id/1013/400/400",
        "https://picsum.photos/id/1014/400/400",
        "https://picsum.photos/id/1015/400/400",
        "https://picsum.photos/id/1016/400/400"
    ]

    func updateCacheConfig() {
        customConfig = ConfigBuilder()
            .disableSaveToStorage()
            .highLatencyLimit(highLatencyLimit)
            .lowLatencyLimit(lowLatencyLimit)
            .build()

        updateCacheStats()
    }

    func loadHighLatencyImages() {
        isLoading = true
        highLatencyImages.removeAll()

        updateCacheConfig()

        let manager = ImageDownloaderManager.instance(for: customConfig)

        for urlString in imageURLs {
            guard let url = URL(string: urlString) else { continue }

            manager.requestImage(
                at: url,
                caller: self,
                updateLatency: .high,  // High latency - will be evicted less frequently
                completion: { [weak self, urlString] image, error, fromCache, fromStorage in
                    Task { @MainActor in
                        guard let self = self else { return }

                        if let image = image {
                            self.highLatencyImages[urlString] = image
                        }

                        // Check if all done
                        if self.highLatencyImages.count >= self.imageURLs.count {
                            self.isLoading = false
                            self.updateCacheStats()
                        }
                    }
                }
            )
        }
    }

    func loadLowLatencyImages() {
        isLoading = true
        lowLatencyImages.removeAll()

        updateCacheConfig()

        let manager = ImageDownloaderManager.instance(for: customConfig)

        for urlString in imageURLs {
            guard let url = URL(string: urlString) else { continue }

            manager.requestImage(
                at: url,
                caller: self,
                updateLatency: .low,  // Low latency - will be evicted more frequently
                completion: { [weak self, urlString] image, error, fromCache, fromStorage in
                    Task { @MainActor in
                        guard let self = self else { return }

                        if let image = image {
                            self.lowLatencyImages[urlString] = image
                        }

                        // Check if all done
                        if self.lowLatencyImages.count >= self.imageURLs.count {
                            self.isLoading = false
                            self.updateCacheStats()
                        }
                    }
                }
            )
        }
    }

    func clearLayout() {
        highLatencyImages.removeAll()
        lowLatencyImages.removeAll()
    }

    func clearCache() {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        manager.clearAllCache()
        updateCacheStats()
    }

    func clearHighLatencyCache() {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        // Note: Library has internal naming swapped, so we pass false for high
        manager.clearCache(isHighLatency: false)
        updateCacheStats()
    }

    func clearLowLatencyCache() {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        // Note: Library has internal naming swapped, so we pass true for low
        manager.clearCache(isHighLatency: true)
        updateCacheStats()
    }

    func updateCacheStats() {
        Task {
            guard let config = customConfig else { return }
            let manager = ImageDownloaderManager.instance(for: config)
            
            let highCount = await manager.highLatencyCacheCount()
            let lowCount = await manager.lowLatencyCacheCount()
            
            await MainActor.run {
                cacheStats = CacheStats(
                    highLatencyCount: highCount,
                    lowLatencyCount: lowCount,
                    highLatencyLimit: highLatencyLimit,
                    lowLatencyLimit: lowLatencyLimit
                )
            }
        }
    }
}

struct CacheStats {
    let highLatencyCount: Int
    let lowLatencyCount: Int
    let highLatencyLimit: Int
    let lowLatencyLimit: Int

    var highLatencyPercentage: Double {
        guard highLatencyLimit > 0 else { return 0 }
        return Double(highLatencyCount) / Double(highLatencyLimit) * 100
    }

    var lowLatencyPercentage: Double {
        guard lowLatencyLimit > 0 else { return 0 }
        return Double(lowLatencyCount) / Double(lowLatencyLimit) * 100
    }
}
