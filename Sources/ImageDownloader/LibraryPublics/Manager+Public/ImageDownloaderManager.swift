//
//  ImageDownloaderManager.swift
//  ImageDownloader
//
//  Main coordinator for image downloading, caching, and storage
//

import Foundation
import UIKit

@objc @objcMembers
public class ImageDownloaderManager: NSObject {
    /// Singleton & Factory
    /// Shared singleton instance with default configuration
    @objc public static let shared = ImageDownloaderManager()
    
    /// Get or create a manager instance for a specific configuration
    /// - Parameter config: Custom configuration (nil = use shared instance)
    /// - Returns: ImageDownloaderManager configured with the specified config
    @objc public static func instance(for config: IDConfiguration? = nil) -> ImageDownloaderManager {
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
    
    
    // MARK: - Library private Properties
    var cacheAgent: CacheAgent
    var storageAgent: StorageAgent
    var networkAgent: NetworkAgent
    var configuration: IDConfiguration

    let managerQueue = DispatchQueue(label: "com.imagedownloader.manager.queue")
    /// Manager instances cache for custom configurations
    private static var instances: [String: ImageDownloaderManager] = [:]
    private static let instancesLock = NSLock()

    // MARK: - Caller Registry
    /// Stores waiting callers and their completion blocks
    /// Key: URL string, Value: Array of (weak caller, completion, progress)
    private var callerRegistry: [String: [(caller: WeakBox<AnyObject>, completion: ImageCompletionBlock, progress: ImageProgressBlock?)]] = [:]
    private let registryLock = NSLock()
    private var cleanupTimer: Timer?

    // MARK: - Initialization
    /// Private initializer for singleton
    private override init() {
        self.configuration = .default
        let (networkConfig, cacheConfig, storageConfig) = configuration.toInternalConfigs()

        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
        super.init()
        startCleanupTimer()
    }
    
    /// Internal initializer with injectable protocol-based configuration
    init(config: IDConfiguration) {
        self.configuration = config
        let (networkConfig, cacheConfig, storageConfig) = config.toInternalConfigs()

        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
        super.init()
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.cleanupDeadCallers()
        }
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
    
    /// Register a caller waiting for an image
    /// - Parameters:
    ///   - url: The URL being requested
    ///   - caller: The object making the request (stored weakly)
    ///   - completion: Completion block to call when image is ready
    ///   - progress: Optional progress block
    func registerCaller(
        url: URL,
        caller: AnyObject?,
        completion: @escaping ImageCompletionBlock,
        progress: ImageProgressBlock?
    ) {
        guard let caller = caller else { return }

        let urlKey = url.absoluteString

        registryLock.lock()
        defer { registryLock.unlock() }

        // Add to registry
        let entry = (caller: WeakBox(caller), completion: completion, progress: progress)
        callerRegistry[urlKey, default: []].append(entry)
    }

    /// Notify all waiting callers for a URL
    /// - Parameters:
    ///   - url: The URL that finished loading
    ///   - image: The loaded image (nil if error)
    ///   - error: The error (nil if success)
    ///   - fromCache: Whether image came from cache
    ///   - fromStorage: Whether image came from storage
    func notifyCallers(
        url: URL,
        image: UIImage?,
        error: Error?,
        fromCache: Bool,
        fromStorage: Bool
    ) {
        let urlKey = url.absoluteString

        registryLock.lock()
        let waiters = callerRegistry[urlKey] ?? []
        callerRegistry.removeValue(forKey: urlKey)
        registryLock.unlock()

        // Notify all waiters (only if caller still alive)
        for waiter in waiters {
            // Check if caller is still alive
            if waiter.caller.value != nil {
                // Call on main thread
                DispatchQueue.main.async {
                    waiter.completion(image, error, fromCache, fromStorage)
                }
            }
        }
    }

    /// Clean up dead callers periodically
    func cleanupDeadCallers() {
        registryLock.lock()
        defer { registryLock.unlock() }

        // Remove entries where caller is nil
        for (urlKey, waiters) in callerRegistry {
            let aliveWaiters = waiters.filter { $0.caller.value != nil }
            if aliveWaiters.isEmpty {
                callerRegistry.removeValue(forKey: urlKey)
            } else {
                callerRegistry[urlKey] = aliveWaiters
            }
        }
    }
}
