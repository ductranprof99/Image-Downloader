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
    /// - Parameters:
    ///   - url: The URL of the image to download
    ///   - updateLatency: Cache priority
    ///   - downloadPriority: Download priority
    /// - Returns: ImageResult with the loaded image
    /// - Throws: CancellationError if Task is cancelled, ImageDownloaderError on failure
//    func requestImageAsync(
//        at url: URL,
//        updateLatency: ResourceUpdateLatency = .high,
//        downloadPriority: DownloadPriority = .high,
//    ) async throws -> ImageResult {
//        try Task.checkCancellation()
//
//        let cacheResult = await self.cacheAgent.image(for: url)
//        switch cacheResult {
//        case let .hit(img):
//            return ImageResult(
//                image: img,
//                url: url,
//                fromCache: true,
//                fromStorage: false
//            )
//        case .wait:
//            break
//        case .miss:
//            break
//        }
//
//        // Cache miss - need to download
//        // TODO: implement later
//    }

}
