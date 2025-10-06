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

    // MARK: - Properties

    public private(set) var observerManager: ObserverManager
    public private(set) var configuration: ImageDownloaderConfiguration

    private var cacheAgent: CacheAgent
    private var storageAgent: StorageAgent
    private var networkAgent: NetworkAgent
    private let managerQueue = DispatchQueue(label: "com.imagedownloader.manager.queue")

    // Store identifier provider for ResourceModel creation
    private var identifierProvider: ResourceIdentifierProvider

    // MARK: - Singleton

    public static let shared = ImageDownloaderManager()

    // MARK: - Initialization

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
        self.networkAgent = NetworkAgent(maxConcurrentDownloads: 4)
        self.observerManager = ObserverManager()

        super.init()

        self.cacheAgent.delegate = self
    }

    // MARK: - Configuration

    /// Configure the manager with Swift configuration struct
    public func configure(_ configuration: ImageDownloaderConfiguration) {
        self.configuration = configuration

        // Store identifier provider for ResourceModel creation
        self.identifierProvider = configuration.identifierProvider

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
        networkAgent = NetworkAgent(maxConcurrentDownloads: configuration.maxConcurrentDownloads)
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
        managerQueue.async { [weak self] in
            guard let self = self else { return }

            // Step 1: Check cache
            if let cachedImage = self.cacheAgent.image(for: url) {
                self.observerManager.notifyImageDidLoad(url: url, fromCache: true, fromStorage: false)

                // Report instant progress for cached images
                if let progress = progress {
                    DispatchQueue.main.async {
                        progress(1.0)
                    }
                }

                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(cachedImage, nil, true, false)
                    }
                }
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

                    if let completion = completion {
                        DispatchQueue.main.async {
                            completion(storageImage, nil, false, true)
                        }
                    }
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

    // MARK: - Private Methods

    /// Convert NSError to ImageDownloaderError
    private func convertToImageDownloaderError(_ error: Error) -> ImageDownloaderError {
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

    private func downloadImageFromNetwork(
        at url: URL,
        priority: ResourcePriority,
        shouldSaveToStorage: Bool,
        progress: ImageProgressBlock?,
        completion: ImageCompletionBlock?,
        caller: AnyObject?
    ) {
        observerManager.notifyWillStartDownloading(url: url)

        networkAgent.downloadResource(
            at: url,
            priority: priority,
            progress: { [weak self] downloadProgress in
                guard let self = self else { return }

                // Forward progress
                self.observerManager.notifyDownloadProgress(url: url, progress: downloadProgress)
                if let progress = progress {
                    DispatchQueue.main.async {
                        progress(downloadProgress)
                    }
                }
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

                    if let completion = completion {
                        completion(image, nil, false, false)
                    }
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
