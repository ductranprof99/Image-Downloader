//
//  ImageDownloaderManager+Async.swift
//  ImageDownloader
//
//  Pure async/await API without DispatchQueue mixing
//

import Foundation
import UIKit

extension ImageDownloaderManager {

    // MARK: - Pure Async/Await API (No DispatchQueue Mixing)

    /// Request an image using pure async/await without internal DispatchQueue usage
    /// - Parameters:
    ///   - url: The URL of the image to download
    ///   - priority: The priority level for the download task
    ///   - shouldSaveToStorage: Whether to save to disk storage
    /// - Returns: ImageResult with the loaded image
    /// - Throws: ImageDownloaderError if the download fails
    /// - Note: This method uses pure async/await patterns without mixing with DispatchQueue
    public func requestImageAsync(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil
    ) async throws -> ImageResult {
        let saveToStorage = shouldSaveToStorage ?? configuration.shouldSaveToStorage

        // Check cache (synchronous, thread-safe)
        if let cachedImage = await checkCache(for: url) {
            return ImageResult(
                image: cachedImage,
                url: url,
                fromCache: true,
                fromStorage: false
            )
        }

        // Check storage (async)
        if let storageImage = await checkStorage(for: url, priority: priority) {
            return ImageResult(
                image: storageImage,
                url: url,
                fromCache: false,
                fromStorage: true
            )
        }

        // Download from network (async)
        let image = try await downloadFromNetworkAsync(
            at: url,
            priority: priority,
            shouldSaveToStorage: saveToStorage
        )

        return ImageResult(
            image: image,
            url: url,
            fromCache: false,
            fromStorage: false
        )
    }

    /// Force reload using pure async/await
    /// - Parameters:
    ///   - url: The URL of the image to download
    ///   - priority: The priority level for the download task
    ///   - shouldSaveToStorage: Whether to save to disk storage
    /// - Returns: ImageResult with the loaded image
    /// - Throws: ImageDownloaderError if the download fails
    public func forceReloadImageAsync(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil
    ) async throws -> ImageResult {
        let saveToStorage = shouldSaveToStorage ?? configuration.shouldSaveToStorage

        let image = try await downloadFromNetworkAsync(
            at: url,
            priority: priority,
            shouldSaveToStorage: saveToStorage
        )

        return ImageResult(
            image: image,
            url: url,
            fromCache: false,
            fromStorage: false
        )
    }

    /// Request image with progress updates using AsyncStream
    /// - Parameters:
    ///   - url: The URL of the image to download
    ///   - priority: The priority level for the download task
    ///   - shouldSaveToStorage: Whether to save to disk storage
    /// - Returns: AsyncThrowingStream with progress updates and final result
    public func requestImageWithProgress(
        at url: URL,
        priority: ResourcePriority = .low,
        shouldSaveToStorage: Bool? = nil
    ) -> AsyncThrowingStream<ImageLoadingProgress, Error> {
        let saveToStorage = shouldSaveToStorage ?? configuration.shouldSaveToStorage

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check cache
                    if let cachedImage = await checkCache(for: url) {
                        continuation.yield(.progress(1.0))
                        continuation.yield(.completed(ImageResult(
                            image: cachedImage,
                            url: url,
                            fromCache: true,
                            fromStorage: false
                        )))
                        continuation.finish()
                        return
                    }

                    // Check storage
                    if let storageImage = await checkStorage(for: url, priority: priority) {
                        continuation.yield(.progress(1.0))
                        continuation.yield(.completed(ImageResult(
                            image: storageImage,
                            url: url,
                            fromCache: false,
                            fromStorage: true
                        )))
                        continuation.finish()
                        return
                    }

                    // Download with progress
                    continuation.yield(.progress(0.0))

                    // Use traditional API with progress callback for now
                    // In the future, this could be replaced with a pure async progress API
                    let image = try await withCheckedThrowingContinuation { innerContinuation in
                        var hasResumed = false

                        downloadImageFromNetwork(
                            at: url,
                            priority: priority,
                            shouldSaveToStorage: saveToStorage,
                            progress: { progress in
                                continuation.yield(.progress(progress))
                            },
                            completion: { image, error, _, _ in
                                guard !hasResumed else { return }
                                hasResumed = true

                                if let image = image {
                                    innerContinuation.resume(returning: image)
                                } else if let error = error {
                                    innerContinuation.resume(throwing: self.convertToImageDownloaderError(error))
                                } else {
                                    innerContinuation.resume(throwing: ImageDownloaderError.unknown(
                                        NSError(domain: "ImageDownloader", code: -1, userInfo: nil)
                                    ))
                                }
                            }
                        )
                    }

                    continuation.yield(.completed(ImageResult(
                        image: image,
                        url: url,
                        fromCache: false,
                        fromStorage: false
                    )))
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Async Helpers

    private func checkCache(for url: URL) async -> UIImage? {
        return await Task {
            await cacheAgent.image(for: url)
        }.value
    }

    private func checkStorage(for url: URL, priority: ResourcePriority) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            storageAgent.image(for: url) { [weak self] image in
                if let image = image, let self = self {
                    // Put in cache for fast access next time
                    let cachePriority: CachePriority = (priority == .high) ? .high : .low
                    Task {
                        await self.cacheAgent.setImage(image, for: url, priority: cachePriority)
                    }
                    self.observerManager.notifyImageDidLoad(url: url, fromCache: false, fromStorage: true)
                }
                continuation.resume(returning: image)
            }
        }
    }

    private func downloadFromNetworkAsync(
        at url: URL,
        priority: ResourcePriority,
        shouldSaveToStorage: Bool
    ) async throws -> UIImage {
        observerManager.notifyWillStartDownloading(url: url)

        let image = try await networkAgent.downloadResource(at: url, priority: priority)

        // Update cache
        let cachePriority: CachePriority = (priority == .high) ? .high : .low
        await cacheAgent.setImage(image, for: url, priority: cachePriority)

        // Save to storage if needed
        if shouldSaveToStorage {
            storageAgent.saveImage(image, for: url, completion: nil)
        }

        observerManager.notifyImageDidLoad(url: url, fromCache: false, fromStorage: false)

        return image
    }
}

/// Progress update for async image loading
public enum ImageLoadingProgress {
    case progress(CGFloat)
    case completed(ImageResult)
}
