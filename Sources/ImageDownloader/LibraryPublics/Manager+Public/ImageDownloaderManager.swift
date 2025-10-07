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
    var configuration: IDConfiguration
    
    let managerQueue = DispatchQueue(label: "com.imagedownloader.manager.queue")
    // Store identifier provider for ResourceModel creation
    private var identifierProvider: ResourceIdentifierProvider
    /// Manager instances cache for custom configurations
    private static var instances: [String: ImageDownloaderManager] = [:]
    private static let instancesLock = NSLock()
    private(set) var observerManager: ObserverManager
    
    /// Singleton & Factory
    /// Shared singleton instance with default configuration
    public static let shared = ImageDownloaderManager()
    
    /// Get or create a manager instance for a specific configuration
    /// - Parameter config: Custom configuration (nil = use shared instance)
    /// - Returns: ImageDownloaderManager configured with the specified config
    public static func instance(for config: IDConfiguration? = nil) -> ImageDownloaderManager {
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
        self.identifierProvider = configuration.storage.identifierProvider
        let (networkConfig, cacheConfig, storageConfig) = configuration.toInternalConfigs()
        
        // Update agents with new configuration
        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
        observerManager = ObserverManager()
        super.init()
    }
    
    /// Internal initializer with injectable protocol-based configuration
    init(config: IDConfiguration) {
        // Convert protocol config to IDConfiguration
        self.configuration = config
        let (networkConfig, cacheConfig, storageConfig) = config.toInternalConfigs()
        // Store identifier provider
        self.identifierProvider = config.storage.identifierProvider

        // Initialize agents with protocol config
        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
        observerManager = ObserverManager()
        super.init()
//        self.cacheAgent.delegate = self
    }
}


// MARK: - Library private Methods
extension ImageDownloaderManager {
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
                    Task {
                        await self.cacheAgent.setImage(image, for: url, priority: cachePriority)
                    }
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
            }
        )
    }
}
