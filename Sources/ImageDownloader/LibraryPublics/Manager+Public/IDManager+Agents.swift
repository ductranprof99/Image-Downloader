//
//  public.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

// MARK: - Configuration function
extension ImageDownloaderManager {
    /// Configure the manager with Objective-C configuration object
    @objc public func configure(_ configuration: IDConfiguration) {
        self.configuration = configuration
        let (networkConfig, cacheConfig, storageConfig) = configuration.toInternalConfigs()
        cacheAgent = CacheAgent(config: cacheConfig)
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
    }
}

// MARK: - Request image
extension ImageDownloaderManager {
    // MARK: - Cancel Requests
    @objc public func cancelRequest(for url: URL, caller: AnyObject?) {
        // Note: caller parameter ignored in new actor-based implementation
        // All callbacks for the same URL share the same Task
        if caller != nil {
            
        } else {
            // Cancel all task
            networkAgent.cancelDownload(for: url)
        }
    }
    
    @objc public func cancelAllRequests(for url: URL) {
        networkAgent.cancelDownload(for: url)
    }
    
    // MARK: - Cache + Storage Management
    @objc public func clearCache(url: URL) {
        Task {
            await cacheAgent.clearCache(url: url)
        }
    }
    
    @objc public func clearCache(isHighLatency: Bool) {
        Task {
            await cacheAgent.clearCache(isHighLatency: isHighLatency)
        }
    }
    
    @objc public func clearAllCache() {
        Task {
            await cacheAgent.clearAllCache()
        }
    }
    @objc public func hardReset() {
        Task {
            await cacheAgent.clearAllCache()
        }
        storageAgent.removeAll()
    }
    
    // MARK: - Storage
    @objc public func storagePath() -> String {
        return storageAgent.storagePath()
    }
    
    @objc public func storagePathURL() -> URL {
        return storageAgent.storageURL()
    }
    
    @objc public func clearStorage() {
        storageAgent.removeAll()
    }
    
    @objc public func filePath(for url: URL) -> String? {
        return storageAgent.filePath(for: url)
    }

}
