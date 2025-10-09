//
//  IDManager+Debug.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


// MARK: - Debugging
public extension ImageDownloaderManager {
    public func cacheSizeHighLatency() async -> Int {
        if configuration.isDebug {
            return await cacheAgent.highPriorityCacheCount()
        } else {
            return 0
        }
    }
    
    public func cacheSizeLowLatency() async -> Int {
        if configuration.isDebug {
            return await cacheAgent.lowPriorityCacheCount()
        } else {
            return 0
        }
    }
    
    public func storageSizeBytes() -> UInt {
        if configuration.isDebug {
            return storageAgent.currentStorageSize()
        } else {
            return 0
        }
    }
    
    public func storedImageCount() -> Int {
        if configuration.isDebug {
            return storageAgent.fileCount()
        } else {
            return 0
        }
    }
    
    public func activeDownloadsCountAsync() async -> Int {
        if configuration.isDebug {
            return networkAgent.activeDownloadCount
        } else {
            return 0
        }
        
    }
    
    public func queuedDownloadsCount() async -> Int {
        if configuration.isDebug {
            return networkAgent.pendingDownloadCount
        } else {
            return 0
        }
    }
}
