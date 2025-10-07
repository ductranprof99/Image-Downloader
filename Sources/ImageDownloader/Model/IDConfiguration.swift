//
//  IDConfiguration.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//


import Foundation
// MARK: - Objective-C Compatible Configuration

/// Objective-C compatible configuration class
@objc public class IDConfiguration: NSObject {

    // MARK: - Network Settings
//    @objc public var enableBackgroundTasks: Bool = true
//    @objc public var maxRetries: Int = 3
//    @objc public var retryBaseDelay: TimeInterval = 1.0
    @objc public var maxConcurrentDownloads: Int
    @objc public var timeout: TimeInterval

    // MARK: - Cache Settings
//    @objc public var highPriorityLimit: Int = 50
//    @objc public var lowPriorityLimit: Int = 100
    @objc public var highCachePriority: Int
    @objc public var lowCachePriority: Int

    // MARK: - Storage Settings

    @objc public var storagePath: String?
    @objc public var shouldSaveToStorage: Bool

    // MARK: - Advanced Settings

    @objc public var enableDebugLogging: Bool
    @objc public var retryPolicy: IDRetryPolicy
    @objc public var customHeaders: [String: String]?
    @objc public var allowsCellularAccess: Bool

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
        self.retryPolicy = IDRetryPolicy.defaultPolicy()
        self.customHeaders = nil
        self.allowsCellularAccess = true
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
        retryPolicy: IDRetryPolicy,
        customHeaders: [String: String]?,
        allowsCellularAccess: Bool
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
        self.allowsCellularAccess = allowsCellularAccess
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
            retryPolicy: IDRetryPolicy.aggressivePolicy(),
            customHeaders: nil,
            allowsCellularAccess: true
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
            retryPolicy: IDRetryPolicy.conservativePolicy(),
            customHeaders: nil,
            allowsCellularAccess: true
        )
    }

    // MARK: - Conversion

    internal func toSwiftConfiguration() -> ImageDownloaderConfiguration {
        // Extract Swift providers from Objective-C wrappers, or use defaults
        let swiftIdentifierProvider: any ResourceIdentifierProvider
        let swiftPathProvider: any StoragePathProvider
        let swiftCompressionProvider: any ImageCompressionProvider

        if identifierProvider is IDMD5IdentifierProvider {
            swiftIdentifierProvider = MD5IdentifierProvider()
        } else {
            swiftIdentifierProvider = MD5IdentifierProvider()  // Default
        }

        if pathProvider is IDFlatStoragePathProvider {
            swiftPathProvider = FlatStoragePathProvider()
        } else if pathProvider is IDDomainHierarchicalPathProvider {
            swiftPathProvider = DomainHierarchicalPathProvider()
        } else {
            swiftPathProvider = FlatStoragePathProvider()  // Default
        }

        if compressionProvider is IDPNGCompressionProvider {
            swiftCompressionProvider = PNGCompressionProvider()
        } else if compressionProvider is IDJPEGCompressionProvider {
            swiftCompressionProvider = JPEGCompressionProvider(quality: 0.8)
        } else if compressionProvider is IDAdaptiveCompressionProvider {
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
            retryPolicy: retryPolicy.toSwift(),
            customHeaders: customHeaders,
            authenticationHandler: nil,  // Not supported in Objective-C
            allowsCellularAccess: allowsCellularAccess,
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
            retryPolicy: IDRetryPolicy(
                maxRetries: config.retryPolicy.maxRetries,
                baseDelay: config.retryPolicy.baseDelay,
                backoffMultiplier: config.retryPolicy.backoffMultiplier,
                maxDelay: config.retryPolicy.maxDelay
            ),
            customHeaders: config.customHeaders,
            allowsCellularAccess: config.allowsCellularAccess
        )
    }
}

