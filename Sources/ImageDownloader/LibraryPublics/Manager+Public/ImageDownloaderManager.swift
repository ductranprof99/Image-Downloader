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
    static let shared = ImageDownloaderManager()
    
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
    

    // MARK: - Initialization
    /// Private initializer for singleton
    private override init() {
        // Default configuration
        self.configuration = .default
        let (networkConfig, cacheConfig, storageConfig) = configuration.toInternalConfigs()
        
        // Update agents with new configuration
        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
        super.init()
    }
    
    /// Internal initializer with injectable protocol-based configuration
    init(config: IDConfiguration) {
        // Convert protocol config to IDConfiguration
        self.configuration = config
        let (networkConfig, cacheConfig, storageConfig) = config.toInternalConfigs()

        // Initialize agents with protocol config
        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
        super.init()
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
    
    func registerCaller(url: URL, caller: AnyObject?) {
        
    }
    
    func notifyCaller(caller: AnyObject?) {
        
    }
}
