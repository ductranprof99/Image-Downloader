//
//  public.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

// MARK: - Public function
extension ImageDownloaderManager {
    /// Configure the manager with Objective-C configuration object
    @objc public func configure(_ configuration: IDConfiguration) {
        self.configuration = configuration
        let (networkConfig, cacheConfig, storageConfig) = configuration.toInternalConfigs()
        // Update agents with new configuration
        cacheAgent = CacheAgent(config: cacheConfig)
        //        cacheAgent.delegate = self
        
        // Recreate StorageAgent with providers from configuration
        storageAgent = StorageAgent(config: storageConfig)
        networkAgent = NetworkAgent(config: networkConfig)
    }
    
    
    // MARK: - Main API
    
    // MARK: Async/Await API (Swift)
    public func requestImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil,
        progress: ImageProgressBlock? = nil
    ) async throws -> ImageResult {
        let saveToStorage = shouldSaveToStorage ?? configuration.shouldSaveToStorage
        
        return try await withCheckedThrowingContinuation { continuation in
            var isResumed = false
            
            requestImage(
                at: url,
                priority: priority,
                shouldSaveToStorage: saveToStorage,
                progress: progress,
                completion: { image, error, fromCache, fromStorage in
                    guard !isResumed else { return }
                    isResumed = true
                    
                    if let image = image {
                        let result = ImageResult(
                            image: image,
                            url: url,
                            fromCache: fromCache,
                            fromStorage: fromStorage
                        )
                        continuation.resume(returning: result)
                    } else if let error = error {
                        let downloaderError = self.convertToImageDownloaderError(error)
                        continuation.resume(throwing: downloaderError)
                    } else {
                        continuation.resume(throwing: ImageDownloaderError.unknown(
                            NSError(domain: "ImageDownloader", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "Unknown error occurred"
                            ])
                        ))
                    }
                }
            )
        }
    }
    
    /// Force reload using async/await (Swift-only)
    @available(iOS 13.0, macOS 10.15, *)
    public func forceReloadImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil,
        progress: ImageProgressBlock? = nil
    ) async throws -> ImageResult {
        let saveToStorage = shouldSaveToStorage ?? configuration.shouldSaveToStorage
        
        return try await withCheckedThrowingContinuation { continuation in
            var isResumed = false
            
            forceReloadImage(
                at: url,
                priority: priority,
                shouldSaveToStorage: saveToStorage,
                progress: progress,
                completion: { image, error, fromCache, fromStorage in
                    guard !isResumed else { return }
                    isResumed = true
                    
                    if let image = image {
                        let result = ImageResult(
                            image: image,
                            url: url,
                            fromCache: fromCache,
                            fromStorage: fromStorage
                        )
                        continuation.resume(returning: result)
                    } else if let error = error {
                        let downloaderError = self.convertToImageDownloaderError(error)
                        continuation.resume(throwing: downloaderError)
                    } else {
                        continuation.resume(throwing: ImageDownloaderError.unknown(
                            NSError(domain: "ImageDownloader", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "Unknown error occurred"
                            ])
                        ))
                    }
                }
            )
        }
    }
    
    // MARK: Completion Handler API (Objective-C Compatible)
    
    /// Request an image resource with full control over priority, storage, and callbacks
    @objc public func requestImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool = true,
        progress: ImageProgressBlock? = nil,
        completion: ImageCompletionBlock? = nil,
    ) {
        // Wrap callbacks to ensure they run on main thread only
        let mainThreadCompletion: ImageCompletionBlock? = completion.map { block in
            return { image, error, fromCache, fromStorage in
                DispatchQueue.main.async { block(image, error, fromCache, fromStorage) }
            }
        }
        
        managerQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Step 1: Check cache
            if let image = self.cacheAgent.image(for: url) {
                mainThreadCompletion?(image, nil, true, false)
                return
            }
            
            // Step 2: Check storage
            self.storageAgent.image(for: url) { [weak self] storageImage in
                guard let self = self else { return }
                
                if let storageImage = storageImage {
                    // Put in cache for fast access next time
                    let cachePriority: CachePriority = (priority == .high) ? .high : .low
                    Task {
                        await self.cacheAgent.setImage(storageImage, for: url, priority: cachePriority)
                    }
                    
                    self.observerManager.notifyImageDidLoad(url: url, fromCache: false, fromStorage: true)
                    
                    // Report instant progress for storage images
                    if let progress = progress {
                        DispatchQueue.main.async {
                            progress(1.0)
                        }
                    }
                    
                    mainThreadCompletion?(storageImage, nil, false, true)
                } else {
                    // Step 3: Download from network
                    self.downloadImageFromNetwork(
                        at: url,
                        priority: priority,
                        shouldSaveToStorage: shouldSaveToStorage,
                        progress: progress,
                        completion: completion
                    )
                }
            }
        }
    }
    
    /// Simplified API with default parameters
    @objc public func requestImage(at url: URL, completion: ImageCompletionBlock? = nil) {
        requestImage(
            at: url,
            priority: .low,
            shouldSaveToStorage: configuration.shouldSaveToStorage,
            progress: nil,
            completion: completion
        )
    }
    
    /// Force reload (bypass cache/storage, fetch from network)
    @objc public func forceReloadImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool = true,
        progress: ImageProgressBlock? = nil,
        completion: ImageCompletionBlock? = nil,
    ) {
        // Bypass cache and storage, go directly to network
        downloadImageFromNetwork(
            at: url,
            priority: priority,
            shouldSaveToStorage: shouldSaveToStorage,
            progress: progress,
            completion: completion
        )
    }
    
    // MARK: - Cancel Requests
    
    public func cancelRequest(for url: URL, caller: AnyObject?) {
        // Note: caller parameter ignored in new actor-based implementation
        // All callbacks for the same URL share the same Task
        networkAgent.cancelDownload(for: url)
    }
    
    public func cancelAllRequests(for url: URL) {
        networkAgent.cancelDownload(for: url)
    }
    
    // MARK: - Cache + Storage Management
    @objc public func clearLowPriorityCache() {
        Task {
            await cacheAgent.clearLowPriorityCache()
        }
    }
    
    @objc public func clearAllCache() {
        Task {
            await cacheAgent.clearAllCache()
        }
    }
    
    public func clearStorage(completion: ((Bool) -> Void)? = nil) {
        storageAgent.clearAllStorage(completion: completion)
    }
    
    @objc public func hardReset() {
        Task {
            await cacheAgent.hardReset()
        }
        storageAgent.clearAllStorage(completion: nil)
    }
    
    
}

// MARK: - Observer Management
extension ImageDownloaderManager {
    public func addObserver(_ observer: ImageDownloaderObserver) {
        observerManager.addObserver(observer)
    }
    
    public func removeObserver(_ observer: ImageDownloaderObserver) {
        observerManager.removeObserver(observer)
    }
}

// MARK: - Statistics Simple debug
    extension ImageDownloaderManager {
    public func cacheSizeHigh() async -> Int {
        return await cacheAgent.highPriorityCacheCount()
    }
    
    public func cacheSizeLow() async -> Int {
        return await cacheAgent.lowPriorityCacheCount()
    }
    
    public func storageSizeBytes() -> UInt {
        return storageAgent.currentStorageSize()
    }
    
    public func activeDownloadsCount() -> Int {
        // Note: Returns 0 synchronously in new actor-based implementation
        // Use async version for accurate count
        return 0
    }

    public func activeDownloadsCountAsync() async -> Int {
        return await networkAgent.activeDownloadCount
    }

    public func queuedDownloadsCount() -> Int {
        // Note: New actor-based implementation doesn't use a queue
        // All downloads are managed via Swift Concurrency Task system
        return 0
    }
}
