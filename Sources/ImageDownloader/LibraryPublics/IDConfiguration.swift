//
//  IDConfiguration.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//
//  Unified configuration class that works for both Objective-C and Swift

import Foundation

// MARK: - Main Configuration Class

/// Unified configuration class that works for both Objective-C and Swift
/// This replaces both IDConfiguration and ImageDownloaderConfiguration
@objc public class IDConfiguration: NSObject {

    // MARK: - Grouped Configuration Settings

    /// Network configuration (downloads, retry, auth, etc.)
    @objc public var network: IDNetworkConfig

    /// Cache configuration (memory management)
    @objc public var cache: IDCacheConfig

    /// Storage configuration (disk persistence, compression)
    @objc public var storage: IDStorageConfig

    // MARK: - Advanced Settings

    /// Enable debug logging (default: false)
    @objc public var enableDebugLogging: Bool

    // MARK: - Initialization

    /// Initialize with grouped configurations
    /// - Parameters:
    ///   - network: Network configuration
    ///   - cache: Cache configuration
    ///   - storage: Storage configuration
    ///   - enableDebugLogging: Enable debug logging
    @objc public init(
        network: IDNetworkConfig = IDNetworkConfig.defaultConfig(),
        cache: IDCacheConfig = IDCacheConfig.defaultConfig(),
        storage: IDStorageConfig = IDStorageConfig.defaultConfig(),
        enableDebugLogging: Bool = false
    ) {
        self.network = network
        self.cache = cache
        self.storage = storage
        self.enableDebugLogging = enableDebugLogging
        super.init()
    }

    
    // MARK: - Convenience Properties for Direct Access

    // Network properties
    @objc public var maxConcurrentDownloads: Int {
        get { network.maxConcurrentDownloads }
        set { network.maxConcurrentDownloads = newValue }
    }

    @objc public var timeout: TimeInterval {
        get { network.timeout }
        set { network.timeout = newValue }
    }

    @objc public var allowsCellularAccess: Bool {
        get { network.allowsCellularAccess }
        set { network.allowsCellularAccess = newValue }
    }

    @objc public var retryPolicy: IDRetryPolicy {
        get { network.retryPolicy }
        set { network.retryPolicy = newValue }
    }

    @objc public var customHeaders: [String: String]? {
        get { network.customHeaders }
        set { network.customHeaders = newValue }
    }

    public var authenticationHandler: ((inout URLRequest) -> Void)? {
        get { network.authenticationHandler }
        set { network.authenticationHandler = newValue }
    }

    /// Cache properties, remember, not set this variable when downloading, it can lead to un-exepted behavior
    @objc public var highLatencyLimit: Int {
        get { cache.highLatencyLimit }
        set { cache.highLatencyLimit = newValue }
    }

    /// Cache properties, remember, not set this variable when downloading, it can lead to un-exepted behavior
    @objc public var lowLatencyLimit: Int {
        get { cache.lowLatencyLimit }
        set { cache.lowLatencyLimit = newValue }
    }

    /// Cache properties, remember, not set this variable when downloading, it can lead to un-exepted behavior
    @objc public var clearLowPriorityOnMemoryWarning: Bool {
        get { cache.clearLowPriorityOnMemoryWarning }
        set { cache.clearLowPriorityOnMemoryWarning = newValue }
    }

    /// Cache properties, remember, not set this variable when downloading, it can lead to un-exepted behavior
    @objc public var clearAllOnMemoryWarning: Bool {
        get { cache.clearAllOnMemoryWarning }
        set { cache.clearAllOnMemoryWarning = newValue }
    }

    // Storage properties
    @objc public var shouldSaveToStorage: Bool {
        get { storage.shouldSaveToStorage }
        set { storage.shouldSaveToStorage = newValue }
    }

    @objc public var storagePath: String? {
        get { storage.storagePath }
        set { storage.storagePath = newValue }
    }

    @objc public var identifierProvider: AnyObject? {
        get { storage.identifierProvider }
        set {
            if let a = newValue as? ResourceIdentifierProvider {
                storage.identifierProvider = a
            }
        }
    }
    
    @objc public var isDebug: Bool {
        get {
            enableDebugLogging
        }
        set {
            enableDebugLogging = newValue
        }
    }

    @objc public var pathProvider: AnyObject? {
        get { storage.pathProvider }
        set {
            if let a = newValue as? StoragePathProvider {
                storage.pathProvider = a
            }
        }
    }

    @objc public var compressionProvider: AnyObject? {
        get { storage.compressionProvider }
        set {
            if let a = newValue as? ImageCompressionProvider {
                storage.compressionProvider = a
            }
        }
    }

    // MARK: - Internal Conversion

    func toInternalConfigs() -> (network: NetworkConfig, cache: CacheConfig, storage: StorageConfig) {
        return (
            network: network.toInternalConfig(),
            cache: cache.toInternalConfig(),
            storage: storage.toInternalConfig()
        )
    }
}

// MARK: - Static Properties for Backward Compatibility

extension IDConfiguration {
    // MARK: - Presets
    /// Default configuration (backward compatibility)
    @objc public static let `default` = IDConfiguration.defaultConfiguration()

    /// High performance configuration (backward compatibility)
    @objc public static let highPerformance = IDConfiguration.highPerformanceConfiguration()

    /// Low memory configuration (backward compatibility)
    @objc public static let lowMemory = IDConfiguration.lowMemoryConfiguration()
    
    /// Legacy
    @objc public static let fast = IDConfiguration.fastConfig()
    
    /// Legacy
    @objc public static let offlineFirst = IDConfiguration.offlineFirstConfig()
    
    // MARK: - Internal
    /// Default configuration with standard settings
    static func defaultConfiguration() -> IDConfiguration {
        return IDConfiguration()
    }

    /// High performance configuration (more cache, more concurrent downloads)
    static func highPerformanceConfiguration() -> IDConfiguration {
        let networkConfig = IDNetworkConfig(
            maxConcurrentDownloads: 8,
            timeout: 30,
            retryPolicy: IDRetryPolicy.aggressivePolicy()
        )
        
        let cacheConfig = IDCacheConfig(
            highLatencyLimit: 100,
            lowLatencyLimit: 200
        )
        
        return IDConfiguration(
            network: networkConfig,
            cache: cacheConfig,
            storage: IDStorageConfig.defaultConfig(),
            enableDebugLogging: false
        )
    }

    /// Low memory configuration (less cache, fewer concurrent downloads)
    static func lowMemoryConfiguration() -> IDConfiguration {
        
        let networkConfig = IDNetworkConfig(
            maxConcurrentDownloads: 2,
            timeout: 30,
            retryPolicy: IDRetryPolicy.conservativePolicy()
        )
        
        let cacheConfig = IDCacheConfig(
            highLatencyLimit: 20,
            lowLatencyLimit: 50
        )
        
        return IDConfiguration(
            network: networkConfig,
            cache: cacheConfig,
            storage: IDStorageConfig.defaultConfig(),
            enableDebugLogging: false
        )
    }
    
    static func fastConfig() -> IDConfiguration {
        let networkConfig = IDNetworkConfig(
            maxConcurrentDownloads: 8,
            timeout: 20,
            retryPolicy: .aggressivePolicy()
        )
        
        // Large cache for better hit rate
        let cacheConfig = IDCacheConfig(
            highLatencyLimit: 100,
            lowLatencyLimit: 200
        )
        
        // JPEG compression for faster disk I/O
        let  storageConfig = IDStorageConfig(
            shouldSaveToStorage: true,
            compressionProvider: JPEGCompressionProvider(quality: 0.8)
        )
        
        return IDConfiguration(
            network: networkConfig,
            cache: cacheConfig,
            storage: storageConfig,
            enableDebugLogging: false
        )
    }
    
    static func offlineFirstConfig() -> IDConfiguration {
        let networkConfig = IDNetworkConfig(
            maxConcurrentDownloads: 2,
            timeout: 60,
            allowsCellularAccess: false,
            retryPolicy: .conservativePolicy()
        )
        
        // Large cache for better hit rate
        let cacheConfig = IDCacheConfig(
            highLatencyLimit: 200,
            lowLatencyLimit: 500,
            clearLowPriorityOnMemoryWarning: false
        )
        
        // JPEG compression for faster disk I/O
        let  storageConfig = IDStorageConfig(
            shouldSaveToStorage: true,
            pathProvider: DomainHierarchicalPathProvider(),
            compressionProvider: AdaptiveCompressionProvider()
        )
        
        return IDConfiguration(
            network: networkConfig,
            cache: cacheConfig,
            storage: storageConfig,
            enableDebugLogging: false
        )
    }
}
