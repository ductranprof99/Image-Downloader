//
//  public.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

// MARK: - Public function
extension ImageDownloaderManager {
    /// Configure the manager with Swift configuration struct
    public func configure(_ configuration: ImageDownloaderConfiguration) {
        setConfiguration(configuration)
        
        // Update agents with new configuration
        cacheAgent = CacheAgent(
            highPriorityLimit: configuration.highCachePriority,
            lowPriorityLimit: configuration.lowCachePriority
        )
        cacheAgent.delegate = self
        
        // Recreate StorageAgent with providers from configuration
        storageAgent = StorageAgent(
            storagePath: configuration.storagePath,
            identifierProvider: configuration.identifierProvider,
            pathProvider: configuration.pathProvider,
            compressionProvider: configuration.compressionProvider
        )
        networkAgent = NetworkAgent(
            maxConcurrentDownloads: configuration.maxConcurrentDownloads,
            timeout: configuration.timeout,
            retryPolicy: configuration.retryPolicy,
            customHeaders: configuration.customHeaders,
            authenticationHandler: configuration.authenticationHandler,
            allowsCellularAccess: configuration.allowsCellularAccess
        )
    }
    
    /// Configure the manager with Objective-C configuration object
    @objc public func configure(_ configuration: IDConfiguration) {
        configure(configuration.toSwiftConfiguration())
    }
    
    /// Legacy configuration method (deprecated but kept for backward compatibility)
    @available(*, deprecated, message: "Use configure(_:) with ImageDownloaderConfiguration instead")
    public func configure(
        maxConcurrentDownloads: Int,
        highCachePriority: Int,
        lowCachePriority: Int,
        storagePath: String?
    ) {
        let config = ImageDownloaderConfiguration(
            maxConcurrentDownloads: maxConcurrentDownloads,
            highCachePriority: highCachePriority,
            lowCachePriority: lowCachePriority,
            storagePath: storagePath
        )
        configure(config)
    }
    
    // MARK: - Main API
    
    // MARK: Async/Await API (Swift)
    
    /// Request an image resource using async/await (Swift-only)
    @available(iOS 13.0, macOS 10.15, *)
    public func requestImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil,
        progress: ImageProgressBlock? = nil,
        caller: AnyObject? = nil
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
                },
                caller: caller
            )
        }
    }
    
    /// Force reload using async/await (Swift-only)
    @available(iOS 13.0, macOS 10.15, *)
    public func forceReloadImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil,
        progress: ImageProgressBlock? = nil,
        caller: AnyObject? = nil
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
                },
                caller: caller
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
        caller: AnyObject? = nil
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
                    self.cacheAgent.setImage(storageImage, for: url, priority: cachePriority)
                    
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
                        completion: completion,
                        caller: caller
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
            completion: completion,
            caller: nil
        )
    }
    
    /// Force reload (bypass cache/storage, fetch from network)
    @objc public func forceReloadImage(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool = true,
        progress: ImageProgressBlock? = nil,
        completion: ImageCompletionBlock? = nil,
        caller: AnyObject? = nil
    ) {
        // Bypass cache and storage, go directly to network
        downloadImageFromNetwork(
            at: url,
            priority: priority,
            shouldSaveToStorage: shouldSaveToStorage,
            progress: progress,
            completion: completion,
            caller: caller
        )
    }
    
    // MARK: - Cancel Requests
    
    public func cancelRequest(for url: URL, caller: AnyObject?) {
        networkAgent.cancelDownload(for: url, caller: caller)
    }
    
    public func cancelAllRequests(for url: URL) {
        networkAgent.cancelAllDownloads(for: url)
    }
    
    // MARK: - Cache Management
    
    public func clearLowPriorityCache() {
        cacheAgent.clearLowPriorityCache()
    }
    
    public func clearAllCache() {
        cacheAgent.clearAllCache()
    }
    
    public func clearStorage(completion: ((Bool) -> Void)? = nil) {
        storageAgent.clearAllStorage(completion: completion)
    }
    
    public func hardReset() {
        cacheAgent.hardReset()
        storageAgent.clearAllStorage(completion: nil)
    }
    
    // MARK: - Observer Management
    
    public func addObserver(_ observer: ImageDownloaderObserver) {
        observerManager.addObserver(observer)
    }
    
    public func removeObserver(_ observer: ImageDownloaderObserver) {
        observerManager.removeObserver(observer)
    }
    
    // MARK: - Network Configuration Helpers
    
    /// Set custom HTTP headers for all network requests
    /// - Parameter headers: Dictionary of header key-value pairs
    public func setCustomHeaders(_ headers: [String: String]) {
        networkAgent.customHeaders = headers
    }
    
    /// Set authentication handler to modify requests before sending
    /// - Parameter handler: Closure that modifies URLRequest (e.g., adds auth token)
    public func setAuthenticationHandler(_ handler: @escaping (inout URLRequest) -> Void) {
        networkAgent.authenticationHandler = handler
    }
    
    /// Update retry policy
    /// - Parameter policy: The new retry policy to use
    public func setRetryPolicy(_ policy: RetryPolicy) {
        networkAgent.retryPolicy = policy
    }
    
    /// Update timeout interval
    /// - Parameter timeout: Timeout in seconds
    public func setTimeout(_ timeout: TimeInterval) {
        networkAgent.timeout = timeout
    }
    
    /// Update cellular access setting
    /// - Parameter allowed: Whether to allow downloads over cellular
    public func setAllowsCellularAccess(_ allowed: Bool) {
        networkAgent.allowsCellularAccess = allowed
    }
    
    // MARK: - Statistics
    
    public func cacheSizeHigh() -> Int {
        return cacheAgent.highPriorityCacheCount()
    }
    
    public func cacheSizeLow() -> Int {
        return cacheAgent.lowPriorityCacheCount()
    }
    
    public func storageSizeBytes() -> UInt {
        return storageAgent.currentStorageSize()
    }
    
    public func activeDownloadsCount() -> Int {
        return networkAgent.activeDownloadCount
    }
    
    public func queuedDownloadsCount() -> Int {
        return networkAgent.queuedTaskCount
    }
}
