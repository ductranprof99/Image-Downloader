//
//  ImageDownloaderConfigProtocol.swift
//  ImageDownloader
//
//  Main configuration protocol for injectable config system
//

import Foundation

/// Main protocol defining complete ImageDownloader configuration
/// This is the entry point for custom configurations
public protocol ImageDownloaderConfigProtocol {

    // MARK: - Sub-Configurations

    /// Network configuration (downloads, retry, auth)
    var networkConfig: NetworkConfigProtocol { get }

    /// Cache configuration (memory management)
    var cacheConfig: CacheConfigProtocol { get }

    /// Storage configuration (disk persistence, compression)
    var storageConfig: StorageConfigProtocol { get }

    // MARK: - Advanced Settings

    /// Enable debug logging (default: false)
    var enableDebugLogging: Bool { get }
}

// MARK: - Default Implementation

extension ImageDownloaderConfigProtocol {
    public var enableDebugLogging: Bool { false }
}

// MARK: - Convenience Getters

extension ImageDownloaderConfigProtocol {

    /// Helper to convert to legacy ImageDownloaderConfiguration
    /// Used internally for backward compatibility
    internal func toLegacyConfiguration() -> ImageDownloaderConfiguration {
        return ImageDownloaderConfiguration(
            maxConcurrentDownloads: networkConfig.maxConcurrentDownloads,
            timeout: networkConfig.timeout,
            highCachePriority: cacheConfig.highPriorityLimit,
            lowCachePriority: cacheConfig.lowPriorityLimit,
            storagePath: storageConfig.storagePath,
            shouldSaveToStorage: storageConfig.shouldSaveToStorage,
            enableDebugLogging: enableDebugLogging,
            retryPolicy: networkConfig.retryPolicy,
            customHeaders: networkConfig.customHeaders,
            authenticationHandler: networkConfig.authenticationHandler,
            allowsCellularAccess: networkConfig.allowsCellularAccess,
            identifierProvider: storageConfig.identifierProvider,
            pathProvider: storageConfig.pathProvider,
            compressionProvider: storageConfig.compressionProvider
        )
    }
}
