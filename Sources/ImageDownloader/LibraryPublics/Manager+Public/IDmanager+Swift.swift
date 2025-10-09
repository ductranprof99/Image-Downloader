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
    case progress(CGFloat)
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
        priority: DownloadPriority = .low,
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
            
        case .miss:
            
        }

        // Download from network (async)
        let image = try await downloadImageAsync(
            at: url,
            downloadPriority: priority
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
    private func downloadImageAsync(
        at: URL,
        downloadPriority: DownloadPriority
    ) -> AsyncThrowingStream<ImageLoadingProgress, Error> {
        return AsyncThrowingStream { continuation in
           
        }
    }
}
