//
//  ImageDownloaderManager+Async.swift
//  ImageDownloader
//
//  Pure async/await API without DispatchQueue mixing
//

import Foundation
import UIKit

// TODO: add a stream method, because some one need to display progress

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

        // Cache miss - need to download
        return try await withCheckedThrowingContinuation { continuation in
            self.requestImage(
                at: url,
                updateLatency: updateLatency,
                downloadPriority: downloadPriority,
                progress: nil,
                completion: { image, error, fromCache, fromStorage in
                    if let image = image {
                        continuation.resume(returning: ImageResult(
                            image: image,
                            url: url,
                            fromCache: fromCache,
                            fromStorage: fromStorage
                        ))
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ImageDownloaderError.unknown(
                            NSError(domain: "ImageDownloader", code: -1, userInfo: nil)
                        ))
                    }
                }
            )
        }
    }

}
