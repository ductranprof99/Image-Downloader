//
//  FastConfig.swift
//  ImageDownloader
//
//  High-performance preset configuration
//

import Foundation

/// High-performance configuration optimized for speed
/// - More concurrent downloads
/// - Larger cache
/// - Aggressive retry
/// - JPEG compression for faster I/O
public struct FastConfig: ImageDownloaderConfigProtocol {
    public var networkConfig: NetworkConfigProtocol
    public var cacheConfig: CacheConfigProtocol
    public var storageConfig: StorageConfigProtocol
    public var enableDebugLogging: Bool

    public init() {
        // Fast network: more concurrent downloads, aggressive retry
        self.networkConfig = DefaultNetworkConfig(
            maxConcurrentDownloads: 8,
            timeout: 20,
            retryPolicy: .aggressive
        )

        // Large cache for better hit rate
        self.cacheConfig = DefaultCacheConfig(
            highPriorityLimit: 100,
            lowPriorityLimit: 200
        )

        // JPEG compression for faster disk I/O
        self.storageConfig = DefaultStorageConfig(
            shouldSaveToStorage: true,
            compressionProvider: JPEGCompressionProvider(quality: 0.8)
        )

        self.enableDebugLogging = false
    }

    /// Singleton instance
    public static let shared = FastConfig()
}
