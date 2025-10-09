//
//  ImageDownloaderManager+Async.swift
//  ImageDownloader
//
//  ObjectiveC Compatinble
//

import Foundation
import UIKit

public typealias ImageCompletionBlock = (UIImage?, Error?, Bool, Bool) -> Void
public typealias ImageProgressBlock = (CGFloat) -> Void


// MARK: - ObjectiveC Compatinble
extension ImageDownloaderManager {
    /// Request an image resource with full control over priority, storage, and callbacks
    @objc public func requestImage(
        at url: URL,
        caller: AnyObject? = nil,
        latency: ResourceLatency = .high,
        downloadPriority: DownloadPriority = .high,
        progress: ImageProgressBlock? = nil,
        completion: ImageCompletionBlock? = nil,
    ) {
        // Wrap callbacks to ensure they run on main thread only
        let mainThreadCompletion: ImageCompletionBlock? = completion.map { block in
            return { image, error, fromCache, fromStorage in
                DispatchQueue.main.async { block(image, error, fromCache, fromStorage) }
            }
        }
        
        Task {
            let cacheResult = await self.cacheAgent.image(for: url)
            switch cacheResult {
            case .hit(let image):
                mainThreadCompletion?(image, nil, true, false)
            case .wait:
                if caller != nil {
                    registerCaller(url: url, caller: caller)
                }
                return
            case .miss:
                let image = await downloadFromNetworkThenUpdate(
                    at: url,
                    downloadPriority: downloadPriority,
                    progress: progress,
                    completion: completion
                )
                
                _ = self.storageAgent.saveImage(image, for: url)
                await self.cacheAgent.setImage(image,
                                               for: url,
                                               isHighLatency: latency.isHighLatency)
                notifyCaller(caller: caller)
            }
        }
    }
    
    /// Simplified API with default parameters, fast, call this again to
    @objc public func requestImage(
        at url: URL,
        completion: ImageCompletionBlock? = nil
    ) {
        requestImage(
            at: url,
            latency: .high,
            progress: nil,
            completion: completion
        )
    }
    
    // MARK: - Private func for objective c selector
    private func downloadFromNetworkThenUpdate (
        at url: URL,
        downloadPriority: DownloadPriority,
        progress: ImageProgressBlock? = nil,
        completion: ImageCompletionBlock? = nil
    ) -> UIImage {
        
    }
}
