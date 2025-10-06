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

    /// Retry policy for failed downloads (default: RetryPolicy.default)
    public var retryPolicy: RetryPolicy

    /// Custom HTTP headers to include in all requests
    public var customHeaders: [String: String]?

    /// Authentication handler to modify requests before sending
    public var authenticationHandler: ((inout URLRequest) -> Void)?

    /// Whether to allow downloads over cellular network (default: true)
    public var allowsCellularAccess: Bool

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
        retryPolicy: RetryPolicy = .default,
        customHeaders: [String: String]? = nil,
        authenticationHandler: ((inout URLRequest) -> Void)? = nil,
        allowsCellularAccess: Bool = true,
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
        self.retryPolicy = retryPolicy
        self.customHeaders = customHeaders
        self.authenticationHandler = authenticationHandler
        self.allowsCellularAccess = allowsCellularAccess
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
