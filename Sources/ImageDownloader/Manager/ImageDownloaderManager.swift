//
//  ImageDownloaderManager.swift
//  ImageDownloader
//
//  Main coordinator for image downloading, caching, and storage
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public typealias ImageCompletionBlock = (UIImage?, Error?, Bool, Bool) -> Void
public typealias ImageProgressBlock = (CGFloat) -> Void

@objc @objcMembers
public class ImageDownloaderManager: NSObject {
    // MARK: - Library private Properties
    var cacheAgent: CacheAgent
    var storageAgent: StorageAgent
    var networkAgent: NetworkAgent
    let managerQueue = DispatchQueue(label: "com.imagedownloader.manager.queue")
    // Store identifier provider for ResourceModel creation
    private var identifierProvider: ResourceIdentifierProvider
    /// Manager instances cache for custom configurations
    private static var instances: [String: ImageDownloaderManager] = [:]
    private static let instancesLock = NSLock()
    
    
    // MARK: - Library public property
    public private(set) var observerManager: ObserverManager
    public private(set) var configuration: ImageDownloaderConfiguration
    
    /// Singleton & Factory
    /// Shared singleton instance with default configuration
    public static let shared = ImageDownloaderManager()
    
    /// Get or create a manager instance for a specific configuration
    /// - Parameter config: Custom configuration (nil = use shared instance)
    /// - Returns: ImageDownloaderManager configured with the specified config
    public static func instance(for config: ImageDownloaderConfigProtocol? = nil) -> ImageDownloaderManager {
        guard let config = config else {
            return shared
        }
        
        // Create a unique key for this configuration
        let configKey = String(describing: type(of: config))
        
        instancesLock.lock()
        defer { instancesLock.unlock() }
        
        if let existing = instances[configKey] {
            return existing
        }
        
        // Create new instance with custom config
        let manager = ImageDownloaderManager(config: config)
        instances[configKey] = manager
        return manager
    }
    
    // MARK: - Initialization
    
    /// Private initializer for singleton
    private override init() {
        // Default configuration
        self.configuration = .default
        self.cacheAgent = CacheAgent(highPriorityLimit: 50, lowPriorityLimit: 100)
        self.identifierProvider = MD5IdentifierProvider()
        self.storageAgent = StorageAgent(
            storagePath: nil,
            identifierProvider: self.identifierProvider,
            pathProvider: FlatStoragePathProvider(),
            compressionProvider: PNGCompressionProvider()
        )
        self.networkAgent = NetworkAgent(
            maxConcurrentDownloads: 4,
            timeout: 30,
            retryPolicy: .default,
            customHeaders: nil,
            authenticationHandler: nil,
            allowsCellularAccess: true
        )
        self.observerManager = ObserverManager()
        
        super.init()
        
        self.cacheAgent.delegate = self
    }
    
    /// Internal initializer with injectable protocol-based configuration
    internal init(config: ImageDownloaderConfigProtocol) {
        // Convert protocol config to legacy format
        let legacyConfig = config.toLegacyConfiguration()
        self.configuration = legacyConfig
        
        // Store identifier provider
        self.identifierProvider = config.storageConfig.identifierProvider
        
        // Initialize agents with protocol config
        self.cacheAgent = CacheAgent(
            highPriorityLimit: config.cacheConfig.highPriorityLimit,
            lowPriorityLimit: config.cacheConfig.lowPriorityLimit
        )
        
        self.storageAgent = StorageAgent(
            storagePath: config.storageConfig.storagePath,
            identifierProvider: config.storageConfig.identifierProvider,
            pathProvider: config.storageConfig.pathProvider,
            compressionProvider: config.storageConfig.compressionProvider
        )
        
        self.networkAgent = NetworkAgent(
            maxConcurrentDownloads: config.networkConfig.maxConcurrentDownloads,
            timeout: config.networkConfig.timeout,
            retryPolicy: config.networkConfig.retryPolicy,
            customHeaders: config.networkConfig.customHeaders,
            authenticationHandler: config.networkConfig.authenticationHandler,
            allowsCellularAccess: config.networkConfig.allowsCellularAccess
        )
        
        self.observerManager = ObserverManager()
        
        super.init()
        
        self.cacheAgent.delegate = self
    }
}


// MARK: - CacheAgentDelegate

extension ImageDownloaderManager: CacheAgentDelegate {
    public func cacheDidEvictImage(for url: URL, priority: CachePriority) {
        // When high priority cache evicts an image, we could save it to storage
        // For now, we assume images are already saved during download if needed
        if priority == .high {
            // In production, you might want to implement saving evicted high-priority images
        }
    }
}


// MARK: - Library private Methods
extension ImageDownloaderManager {
    func setConfiguration(_ configuration: ImageDownloaderConfiguration) {
        self.configuration = configuration
        
        // Store identifier provider for ResourceModel creation
        self.identifierProvider = configuration.identifierProvider
    }
    
    /// Convert NSError to ImageDownloaderError
    func convertToImageDownloaderError(_ error: Error) -> ImageDownloaderError {
        if let downloaderError = error as? ImageDownloaderError {
            return downloaderError
        }

        let nsError = error as NSError

        // Check for common error codes
        switch nsError.code {
        case NSURLErrorCancelled:
            return .cancelled
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkError(error)
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorBadURL, NSURLErrorUnsupportedURL:
            return .invalidURL
        case NSURLErrorResourceUnavailable, NSURLErrorFileDoesNotExist:
            return .notFound
        default:
            // Check domain
            if nsError.domain == "ImageDownloader.Manager" || nsError.domain == "com.imagedownloader.error" {
                return .unknown(error)
            }
            return .networkError(error)
        }
    }

    func downloadImageFromNetwork(
        at url: URL,
        priority: ResourcePriority,
        shouldSaveToStorage: Bool,
        progress: ImageProgressBlock?,
        completion: ImageCompletionBlock?,
        caller: AnyObject?
    ) {
        // Ensure callbacks run on main thread
        let mainThreadProgress: ImageProgressBlock? = progress.map { block in
            return { progress in
                DispatchQueue.main.async { block(progress) }
            }
        }
        
        let mainThreadCompletion: ImageCompletionBlock? = completion.map { block in
            return { image, error, fromCache, fromStorage in
                DispatchQueue.main.async { block(image, error, fromCache, fromStorage) }
            }
        }
        observerManager.notifyWillStartDownloading(url: url)

        networkAgent.downloadResource(
            at: url,
            priority: priority,
            progress: { [weak self] downloadProgress in
                guard let self = self else { return }

                // Forward progress
                self.observerManager.notifyDownloadProgress(url: url, progress: downloadProgress)
                mainThreadProgress?(downloadProgress)
            },
            completion: { [weak self] image, error in
                guard let self = self else { return }

                if let image = image {
                    // Success: update cache
                    let cachePriority: CachePriority = (priority == .high) ? .high : .low
                    self.cacheAgent.setImage(image, for: url, priority: cachePriority)

                    // Save to storage if needed
                    if shouldSaveToStorage {
                        self.storageAgent.saveImage(image, for: url, completion: nil)
                    }

                    self.observerManager.notifyImageDidLoad(url: url, fromCache: false, fromStorage: false)

                    mainThreadCompletion?(image, nil, false, false)
                } else {
                    // Failure
                    let finalError = error ?? NSError(
                        domain: "ImageDownloader.Manager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown download error"]
                    )

                    self.observerManager.notifyImageDidFail(url: url, error: finalError)

                    if let completion = completion {
                        completion(nil, finalError, false, false)
                    }
                }
            },
            caller: caller
        )
    }
}
