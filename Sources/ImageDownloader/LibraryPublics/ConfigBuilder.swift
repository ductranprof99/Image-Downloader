//
//  ConfigBuilder.swift
//  ImageDownloader
//
//  Fluent API for building custom configurations
//

import Foundation

/// Fluent builder for creating custom ImageDownloader configurations
public class ConfigBuilder {
    private var networkConfig: NetworkConfig = NetworkConfig()
    private var cacheConfig: CacheConfig = CacheConfig()
    private var storageConfig: StorageConfig = StorageConfig()
    private var debugLogging: Bool = false

    public init() {}

    // MARK: - Network Configuration

    @discardableResult
    public func maxConcurrentDownloads(_ count: Int) -> Self {
        networkConfig.maxConcurrentDownloads = count
        return self
    }

    @discardableResult
    public func timeout(_ seconds: TimeInterval) -> Self {
        networkConfig.timeout = seconds
        return self
    }

    @discardableResult
    public func allowsCellularAccess(_ allow: Bool) -> Self {
        networkConfig.allowsCellularAccess = allow
        return self
    }

    @discardableResult
    public func retryPolicy(_ policy: RetryPolicy) -> Self {
        networkConfig.retryPolicy = policy
        return self
    }

    @discardableResult
    public func customHeaders(_ headers: [String: String]?) -> Self {
        networkConfig.customHeaders = headers
        return self
    }

    @discardableResult
    public func authenticationHandler(_ handler: ((inout URLRequest) -> Void)?) -> Self {
        networkConfig.authenticationHandler = handler
        return self
    }

    // MARK: - Cache Configuration

    @discardableResult
    public func highPriorityLimit(_ limit: Int) -> Self {
        cacheConfig.highPriorityLimit = limit
        return self
    }

    @discardableResult
    public func lowPriorityLimit(_ limit: Int) -> Self {
        cacheConfig.lowPriorityLimit = limit
        return self
    }

    @discardableResult
    public func clearLowPriorityOnMemoryWarning(_ clear: Bool) -> Self {
        cacheConfig.clearLowPriorityOnMemoryWarning = clear
        return self
    }

    @discardableResult
    public func clearAllOnMemoryWarning(_ clear: Bool) -> Self {
        cacheConfig.clearAllOnMemoryWarning = clear
        return self
    }

    // MARK: - Storage Configuration

    @discardableResult
    public func shouldSaveToStorage(_ save: Bool) -> Self {
        storageConfig.shouldSaveToStorage = save
        return self
    }

    @discardableResult
    public func storagePath(_ path: String?) -> Self {
        storageConfig.storagePath = path
        return self
    }

    @discardableResult
    public func identifierProvider(_ provider: any ResourceIdentifierProvider) -> Self {
        storageConfig.identifierProvider = provider
        return self
    }

    @discardableResult
    public func pathProvider(_ provider: any StoragePathProvider) -> Self {
        storageConfig.pathProvider = provider
        return self
    }

    @discardableResult
    public func compressionProvider(_ provider: any ImageCompressionProvider) -> Self {
        storageConfig.compressionProvider = provider
        return self
    }

    // MARK: - Advanced Configuration

    @discardableResult
    public func enableDebugLogging(_ enable: Bool = true) -> Self {
        debugLogging = enable
        return self
    }

    // MARK: - Build

    /// Build the final configuration as IDConfiguration (public API)
    public func build() -> IDConfiguration {
        let network = IDNetworkConfig(
            maxConcurrentDownloads: networkConfig.maxConcurrentDownloads,
            timeout: networkConfig.timeout,
            allowsCellularAccess: networkConfig.allowsCellularAccess,
            retryPolicy: IDRetryPolicy(from: networkConfig.retryPolicy)
        )
        network.customHeaders = networkConfig.customHeaders
        network.authenticationHandler = networkConfig.authenticationHandler

        let cache = IDCacheConfig(
            highPriorityLimit: cacheConfig.highPriorityLimit,
            lowPriorityLimit: cacheConfig.lowPriorityLimit,
            clearLowPriorityOnMemoryWarning: cacheConfig.clearLowPriorityOnMemoryWarning,
            clearAllOnMemoryWarning: cacheConfig.clearAllOnMemoryWarning
        )

        let storage = IDStorageConfig(
            shouldSaveToStorage: storageConfig.shouldSaveToStorage,
            storagePath: storageConfig.storagePath
        )

        return IDConfiguration(
            network: network,
            cache: cache,
            storage: storage,
            enableDebugLogging: debugLogging
        )
    }
}

// MARK: - Convenience Static Methods

extension ConfigBuilder {
    /// Start with default configuration
    public static func `default`() -> ConfigBuilder {
        return ConfigBuilder()
    }

    /// Start with high performance preset
    public static func highPerformance() -> ConfigBuilder {
        return ConfigBuilder()
            .maxConcurrentDownloads(8)
            .highPriorityLimit(100)
            .lowPriorityLimit(200)
            .retryPolicy(.default)
    }

    /// Start with low memory preset
    public static func lowMemory() -> ConfigBuilder {
        return ConfigBuilder()
            .maxConcurrentDownloads(2)
            .highPriorityLimit(20)
            .lowPriorityLimit(50)
            .clearLowPriorityOnMemoryWarning(true)
            .clearAllOnMemoryWarning(true)
    }

    /// Start with offline-first preset
    public static func offlineFirst() -> ConfigBuilder {
        return ConfigBuilder()
            .shouldSaveToStorage(true)
            .highPriorityLimit(100)
            .lowPriorityLimit(200)
    }
}
