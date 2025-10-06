//
//  LowMemoryConfig.swift
//  ImageDownloader
//
//  Low memory preset configuration
//

import Foundation

/// Low memory configuration optimized for memory-constrained devices
/// - Minimal cache
/// - Fewer concurrent downloads
/// - Aggressive memory warning handling
public struct LowMemoryConfig: ImageDownloaderConfigProtocol {
    public var networkConfig: NetworkConfigProtocol
    public var cacheConfig: CacheConfigProtocol
    public var storageConfig: StorageConfigProtocol
    public var enableDebugLogging: Bool

    public init() {
        // Minimal network load
        self.networkConfig = DefaultNetworkConfig(
            maxConcurrentDownloads: 2,
            timeout: 30,
            retryPolicy: .default
        )

        // Small cache, aggressive cleanup
        self.cacheConfig = DefaultCacheConfig(
            highPriorityLimit: 20,
            lowPriorityLimit: 50,
            clearLowPriorityOnMemoryWarning: true,
            clearAllOnMemoryWarning: true
        )

        // Rely on storage, not memory
        self.storageConfig = DefaultStorageConfig(
            shouldSaveToStorage: true,
            compressionProvider: JPEGCompressionProvider(quality: 0.7)  // High compression
        )

        self.enableDebugLogging = false
    }

    /// Singleton instance
    public static let shared = LowMemoryConfig()
}
