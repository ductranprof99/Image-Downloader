//
//  ImageDownloaderManager+Async.swift
//  ImageDownloader
//
//  Pure async/await API without DispatchQueue mixing
//

import Foundation
import UIKit

/// Progress update for async image loading for async await
public enum ImageLoadingProgress {
    case loading(CGFloat, CGFloat, CGFloat)
    case completed(ImageResult)
}

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
        updateLatency: ResourceUpdateLatency = .high,
        downloadPriority: DownloadPriority = .high,
    ) async throws -> ImageResult {
        // Check cache (synchronous, thread-safe)
        let cacheResult = await self.cacheAgent.image(for: url)
        switch cacheResult {
        case let .hit(img):
            return ImageResult(
                image: img,
                url: url,
                fromCache: true,
                fromStorage: false
            )
        case .wait:
            break
        case .miss:
            break
        }

        // Download from network (async)
        // TODO: Download, then save to somewhere
    }

    /// Request image with progress updates using AsyncStream
    /// - Parameters:
    ///   - url: The URL of the image to download
    ///   - priority: The priority level for the download task
    ///   - shouldSaveToStorage: Whether to save to disk storage
    /// - Returns: AsyncThrowingStream with progress updates and final result
    private func downloadImageAsync(
        at: URL,
        downloadPriority: DownloadPriority
    ) -> AsyncThrowingStream<ImageLoadingProgress, Error> {
        return AsyncThrowingStream { continuation in
           // TODO
        }
    }
}
