//
//  Configuration.swift
//  ImageDownloader
//
//  Configuration system for ImageDownloader
//

import Foundation

/// Swift configuration struct
public struct ImageDownloaderConfiguration {

    // MARK: - Network Settings

    /// Maximum number of concurrent downloads (default: 4)
    public var maxConcurrentDownloads: Int

    /// Request timeout in seconds (default: 30)
    public var timeout: TimeInterval

    // MARK: - Cache Settings

    /// High priority cache limit (default: 50 images)
    public var highCachePriority: Int

    /// Low priority cache limit (default: 100 images)
    public var lowCachePriority: Int

    // MARK: - Storage Settings

    /// Custom storage path (nil = default Caches directory)
    public var storagePath: String?

    /// Whether to save images to disk storage by default (default: true)
    public var shouldSaveToStorage: Bool

    // MARK: - Advanced Settings

    /// Enable debug logging (default: false)
    public var enableDebugLogging: Bool

    /// Retry failed downloads (default: false)
    public var enableRetry: Bool

    /// Number of retry attempts (default: 3)
    public var retryAttempts: Int

    // MARK: - Customization Providers

    /// Resource identifier provider (default: MD5IdentifierProvider)
    public var identifierProvider: any ResourceIdentifierProvider

    /// Storage path provider (default: FlatStoragePathProvider)
    public var pathProvider: any StoragePathProvider

    /// Image compression provider (default: PNGCompressionProvider)
    public var compressionProvider: any ImageCompressionProvider

    // MARK: - Initialization

    public init(
        maxConcurrentDownloads: Int = 4,
        timeout: TimeInterval = 30,
        highCachePriority: Int = 50,
        lowCachePriority: Int = 100,
        storagePath: String? = nil,
        shouldSaveToStorage: Bool = true,
        enableDebugLogging: Bool = false,
        enableRetry: Bool = false,
        retryAttempts: Int = 3,
        identifierProvider: any ResourceIdentifierProvider = MD5IdentifierProvider(),
        pathProvider: any StoragePathProvider = FlatStoragePathProvider(),
        compressionProvider: any ImageCompressionProvider = PNGCompressionProvider()
    ) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.timeout = timeout
        self.highCachePriority = highCachePriority
        self.lowCachePriority = lowCachePriority
        self.storagePath = storagePath
        self.shouldSaveToStorage = shouldSaveToStorage
        self.enableDebugLogging = enableDebugLogging
        self.enableRetry = enableRetry
        self.retryAttempts = retryAttempts
        self.identifierProvider = identifierProvider
        self.pathProvider = pathProvider
        self.compressionProvider = compressionProvider
    }

    /// Default configuration
    public static let `default` = ImageDownloaderConfiguration()

    /// High performance configuration (more cache, more concurrent downloads)
    public static let highPerformance = ImageDownloaderConfiguration(
        maxConcurrentDownloads: 8,
        highCachePriority: 100,
        lowCachePriority: 200
    )

    /// Low memory configuration (less cache, fewer concurrent downloads)
    public static let lowMemory = ImageDownloaderConfiguration(
        maxConcurrentDownloads: 2,
        highCachePriority: 20,
        lowCachePriority: 50
    )
}

// MARK: - Objective-C Compatible Configuration

/// Objective-C compatible configuration class
@objc public class IDConfiguration: NSObject {

    // MARK: - Network Settings

    @objc public var maxConcurrentDownloads: Int
    @objc public var timeout: TimeInterval

    // MARK: - Cache Settings

    @objc public var highCachePriority: Int
    @objc public var lowCachePriority: Int

    // MARK: - Storage Settings

    @objc public var storagePath: String?
    @objc public var shouldSaveToStorage: Bool

    // MARK: - Advanced Settings

    @objc public var enableDebugLogging: Bool
    @objc public var enableRetry: Bool
    @objc public var retryAttempts: Int

    // MARK: - Customization Providers (Objective-C wrappers)

    @objc public var identifierProvider: AnyObject?
    @objc public var pathProvider: AnyObject?
    @objc public var compressionProvider: AnyObject?

    // MARK: - Initialization

    @objc public override init() {
        self.maxConcurrentDownloads = 4
        self.timeout = 30
        self.highCachePriority = 50
        self.lowCachePriority = 100
        self.storagePath = nil
        self.shouldSaveToStorage = true
        self.enableDebugLogging = false
        self.enableRetry = false
        self.retryAttempts = 3
        self.identifierProvider = nil  // Will use defaults
        self.pathProvider = nil
        self.compressionProvider = nil
        super.init()
    }

    @objc public init(
        maxConcurrentDownloads: Int,
        timeout: TimeInterval,
        highCachePriority: Int,
        lowCachePriority: Int,
        storagePath: String?,
        shouldSaveToStorage: Bool,
        enableDebugLogging: Bool,
        enableRetry: Bool,
        retryAttempts: Int
    ) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.timeout = timeout
        self.highCachePriority = highCachePriority
        self.lowCachePriority = lowCachePriority
        self.storagePath = storagePath
        self.shouldSaveToStorage = shouldSaveToStorage
        self.enableDebugLogging = enableDebugLogging
        self.enableRetry = enableRetry
        self.retryAttempts = retryAttempts
        super.init()
    }

    // MARK: - Presets

    @objc public static func defaultConfiguration() -> IDConfiguration {
        return IDConfiguration()
    }

    @objc public static func highPerformanceConfiguration() -> IDConfiguration {
        return IDConfiguration(
            maxConcurrentDownloads: 8,
            timeout: 30,
            highCachePriority: 100,
            lowCachePriority: 200,
            storagePath: nil,
            shouldSaveToStorage: true,
            enableDebugLogging: false,
            enableRetry: false,
            retryAttempts: 3
        )
    }

    @objc public static func lowMemoryConfiguration() -> IDConfiguration {
        return IDConfiguration(
            maxConcurrentDownloads: 2,
            timeout: 30,
            highCachePriority: 20,
            lowCachePriority: 50,
            storagePath: nil,
            shouldSaveToStorage: true,
            enableDebugLogging: false,
            enableRetry: false,
            retryAttempts: 3
        )
    }

    // MARK: - Conversion

    internal func toSwiftConfiguration() -> ImageDownloaderConfiguration {
        // Extract Swift providers from Objective-C wrappers, or use defaults
        let swiftIdentifierProvider: any ResourceIdentifierProvider
        let swiftPathProvider: any StoragePathProvider
        let swiftCompressionProvider: any ImageCompressionProvider

        if let idProvider = identifierProvider as? IDMD5IdentifierProvider {
            swiftIdentifierProvider = MD5IdentifierProvider()
        } else {
            swiftIdentifierProvider = MD5IdentifierProvider()  // Default
        }

        if let spProvider = pathProvider as? IDFlatStoragePathProvider {
            swiftPathProvider = FlatStoragePathProvider()
        } else if let spProvider = pathProvider as? IDDomainHierarchicalPathProvider {
            swiftPathProvider = DomainHierarchicalPathProvider()
        } else {
            swiftPathProvider = FlatStoragePathProvider()  // Default
        }

        if let cpProvider = compressionProvider as? IDPNGCompressionProvider {
            swiftCompressionProvider = PNGCompressionProvider()
        } else if let cpProvider = compressionProvider as? IDJPEGCompressionProvider {
            swiftCompressionProvider = JPEGCompressionProvider(quality: 0.8)
        } else if let cpProvider = compressionProvider as? IDAdaptiveCompressionProvider {
            swiftCompressionProvider = AdaptiveCompressionProvider()
        } else {
            swiftCompressionProvider = PNGCompressionProvider()  // Default
        }

        return ImageDownloaderConfiguration(
            maxConcurrentDownloads: maxConcurrentDownloads,
            timeout: timeout,
            highCachePriority: highCachePriority,
            lowCachePriority: lowCachePriority,
            storagePath: storagePath,
            shouldSaveToStorage: shouldSaveToStorage,
            enableDebugLogging: enableDebugLogging,
            enableRetry: enableRetry,
            retryAttempts: retryAttempts,
            identifierProvider: swiftIdentifierProvider,
            pathProvider: swiftPathProvider,
            compressionProvider: swiftCompressionProvider
        )
    }

    internal convenience init(from config: ImageDownloaderConfiguration) {
        self.init(
            maxConcurrentDownloads: config.maxConcurrentDownloads,
            timeout: config.timeout,
            highCachePriority: config.highCachePriority,
            lowCachePriority: config.lowCachePriority,
            storagePath: config.storagePath,
            shouldSaveToStorage: config.shouldSaveToStorage,
            enableDebugLogging: config.enableDebugLogging,
            enableRetry: config.enableRetry,
            retryAttempts: config.retryAttempts
        )
    }
}
