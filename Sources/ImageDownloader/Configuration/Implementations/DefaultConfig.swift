//
//  DefaultConfig.swift
//  ImageDownloader
//
//  Default complete configuration implementation
//

import Foundation

/// Default configuration with standard settings for all components
public struct DefaultConfig: ImageDownloaderConfigProtocol {
    public var networkConfig: NetworkConfigProtocol
    public var cacheConfig: CacheConfigProtocol
    public var storageConfig: StorageConfigProtocol
    public var enableDebugLogging: Bool

    public init(
        networkConfig: NetworkConfigProtocol = DefaultNetworkConfig(),
        cacheConfig: CacheConfigProtocol = DefaultCacheConfig(),
        storageConfig: StorageConfigProtocol = DefaultStorageConfig(),
        enableDebugLogging: Bool = false
    ) {
        self.networkConfig = networkConfig
        self.cacheConfig = cacheConfig
        self.storageConfig = storageConfig
        self.enableDebugLogging = enableDebugLogging
    }

    /// Singleton instance for default configuration
    public static let shared = DefaultConfig()
}
