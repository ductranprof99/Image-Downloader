//
//  ConfigBuilder.swift
//  ImageDownloader
//
//  Fluent API for building custom configurations
//

import Foundation

/// Fluent builder for creating custom ImageDownloader configurations
public class ConfigBuilder {

    private var _networkConfig: NetworkConfigProtocol = DefaultNetworkConfig()
    private var _cacheConfig: CacheConfigProtocol = DefaultCacheConfig()
    private var _storageConfig: StorageConfigProtocol = DefaultStorageConfig()
    private var _enableDebugLogging: Bool = false

    public init() {}

    // MARK: - Network Configuration

    /// Configure network settings
    @discardableResult
    public func network(_ configure: (inout DefaultNetworkConfig) -> Void) -> Self {
        var config = DefaultNetworkConfig()
        configure(&config)
        _networkConfig = config
        return self
    }

    /// Set network config directly
    @discardableResult
    public func network(_ config: NetworkConfigProtocol) -> Self {
        _networkConfig = config
        return self
    }

    /// Quick network presets
    @discardableResult
    public func maxConcurrentDownloads(_ count: Int) -> Self {
        var config = _networkConfig as? DefaultNetworkConfig ?? DefaultNetworkConfig()
        config.maxConcurrentDownloads = count
        _networkConfig = config
        return self
    }

    @discardableResult
    public func timeout(_ seconds: TimeInterval) -> Self {
        var config = _networkConfig as? DefaultNetworkConfig ?? DefaultNetworkConfig()
        config.timeout = seconds
        _networkConfig = config
        return self
    }

    @discardableResult
    public func retryPolicy(_ policy: RetryPolicy) -> Self {
        var config = _networkConfig as? DefaultNetworkConfig ?? DefaultNetworkConfig()
        config.retryPolicy = policy
        _networkConfig = config
        return self
    }

    @discardableResult
    public func customHeaders(_ headers: [String: String]) -> Self {
        var config = _networkConfig as? DefaultNetworkConfig ?? DefaultNetworkConfig()
        config.customHeaders = headers
        _networkConfig = config
        return self
    }

    @discardableResult
    public func authenticationHandler(_ handler: @escaping (inout URLRequest) -> Void) -> Self {
        var config = _networkConfig as? DefaultNetworkConfig ?? DefaultNetworkConfig()
        config.authenticationHandler = handler
        _networkConfig = config
        return self
    }

    @discardableResult
    public func allowsCellularAccess(_ allowed: Bool) -> Self {
        var config = _networkConfig as? DefaultNetworkConfig ?? DefaultNetworkConfig()
        config.allowsCellularAccess = allowed
        _networkConfig = config
        return self
    }

    // MARK: - Cache Configuration

    /// Configure cache settings
    @discardableResult
    public func cache(_ configure: (inout DefaultCacheConfig) -> Void) -> Self {
        var config = DefaultCacheConfig()
        configure(&config)
        _cacheConfig = config
        return self
    }

    /// Set cache config directly
    @discardableResult
    public func cache(_ config: CacheConfigProtocol) -> Self {
        _cacheConfig = config
        return self
    }

    /// Quick cache presets
    @discardableResult
    public func cacheSize(high: Int, low: Int) -> Self {
        var config = _cacheConfig as? DefaultCacheConfig ?? DefaultCacheConfig()
        config.highPriorityLimit = high
        config.lowPriorityLimit = low
        _cacheConfig = config
        return self
    }

    // MARK: - Storage Configuration

    /// Configure storage settings
    @discardableResult
    public func storage(_ configure: (inout DefaultStorageConfig) -> Void) -> Self {
        var config = DefaultStorageConfig()
        configure(&config)
        _storageConfig = config
        return self
    }

    /// Set storage config directly
    @discardableResult
    public func storage(_ config: StorageConfigProtocol) -> Self {
        _storageConfig = config
        return self
    }

    /// Quick storage presets
    @discardableResult
    public func enableStorage(_ enabled: Bool) -> Self {
        var config = _storageConfig as? DefaultStorageConfig ?? DefaultStorageConfig()
        config.shouldSaveToStorage = enabled
        _storageConfig = config
        return self
    }

    @discardableResult
    public func compressionProvider(_ provider: any ImageCompressionProvider) -> Self {
        var config = _storageConfig as? DefaultStorageConfig ?? DefaultStorageConfig()
        config.compressionProvider = provider
        _storageConfig = config
        return self
    }

    @discardableResult
    public func pathProvider(_ provider: any StoragePathProvider) -> Self {
        var config = _storageConfig as? DefaultStorageConfig ?? DefaultStorageConfig()
        config.pathProvider = provider
        _storageConfig = config
        return self
    }

    // MARK: - Debug Settings

    @discardableResult
    public func enableDebugLogging(_ enabled: Bool = true) -> Self {
        _enableDebugLogging = enabled
        return self
    }

    // MARK: - Build

    /// Build the final configuration
    public func build() -> ImageDownloaderConfigProtocol {
        return BuiltConfig(
            networkConfig: _networkConfig,
            cacheConfig: _cacheConfig,
            storageConfig: _storageConfig,
            enableDebugLogging: _enableDebugLogging
        )
    }
}

// MARK: - Built Configuration (Internal)

private struct BuiltConfig: ImageDownloaderConfigProtocol {
    let networkConfig: NetworkConfigProtocol
    let cacheConfig: CacheConfigProtocol
    let storageConfig: StorageConfigProtocol
    let enableDebugLogging: Bool
}

// MARK: - Convenience Static Methods

extension ConfigBuilder {

    /// Start with default configuration
    public static func `default`() -> ConfigBuilder {
        return ConfigBuilder()
    }

    /// Start with fast preset
    public static func fast() -> ConfigBuilder {
        let builder = ConfigBuilder()
        let fast = FastConfig()
        builder._networkConfig = fast.networkConfig
        builder._cacheConfig = fast.cacheConfig
        builder._storageConfig = fast.storageConfig
        return builder
    }

    /// Start with offline-first preset
    public static func offlineFirst() -> ConfigBuilder {
        let builder = ConfigBuilder()
        let offline = OfflineFirstConfig()
        builder._networkConfig = offline.networkConfig
        builder._cacheConfig = offline.cacheConfig
        builder._storageConfig = offline.storageConfig
        return builder
    }

    /// Start with low-memory preset
    public static func lowMemory() -> ConfigBuilder {
        let builder = ConfigBuilder()
        let lowMem = LowMemoryConfig()
        builder._networkConfig = lowMem.networkConfig
        builder._cacheConfig = lowMem.cacheConfig
        builder._storageConfig = lowMem.storageConfig
        return builder
    }
}
