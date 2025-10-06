//
//  OfflineFirstConfig.swift
//  ImageDownloader
//
//  Offline-first preset configuration
//

import Foundation

/// Offline-first configuration optimized for poor connectivity
/// - WiFi only
/// - Massive cache
/// - Conservative retry (don't hammer server)
/// - Adaptive compression (save space)
public struct OfflineFirstConfig: ImageDownloaderConfigProtocol {
    public var networkConfig: NetworkConfigProtocol
    public var cacheConfig: CacheConfigProtocol
    public var storageConfig: StorageConfigProtocol
    public var enableDebugLogging: Bool

    public init() {
        // Conservative network: WiFi only, fewer concurrent, conservative retry
        self.networkConfig = DefaultNetworkConfig(
            maxConcurrentDownloads: 2,
            timeout: 60,
            allowsCellularAccess: false,
            retryPolicy: .conservative
        )

        // Huge cache for offline usage
        self.cacheConfig = DefaultCacheConfig(
            highPriorityLimit: 200,
            lowPriorityLimit: 500,
            clearLowPriorityOnMemoryWarning: false  // Keep as much as possible
        )

        // Adaptive compression to save disk space
        self.storageConfig = DefaultStorageConfig(
            shouldSaveToStorage: true,
            pathProvider: DomainHierarchicalPathProvider(),
            compressionProvider: AdaptiveCompressionProvider()
        )

        self.enableDebugLogging = false
    }

    /// Singleton instance
    public static let shared = OfflineFirstConfig()
}
