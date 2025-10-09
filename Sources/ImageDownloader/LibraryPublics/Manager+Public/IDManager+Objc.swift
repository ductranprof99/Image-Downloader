//
//  ImageDownloaderManager+Async.swift
//  ImageDownloader
//
//  ObjectiveC Compatinble
//

import Foundation
import UIKit

public typealias ImageCompletionBlock = (UIImage?, Error?, Bool, Bool) -> Void
public typealias ImageProgressBlock = (_ progress: CGFloat, _ speed: CGFloat, _ bytes: CGFloat) -> Void


// MARK: - ObjectiveC Compatinble
extension ImageDownloaderManager {
    /// Request an image resource with full control over priority, storage, and callbacks
    @objc public func requestImage(
        at url: URL,
        caller: AnyObject? = nil,
        updateLatency latency: ResourceUpdateLatency = .high,
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
                let image = downloadFromNetworkThenUpdate(
                    at: url,
                    downloadPriority: downloadPriority,
                    progress: { progress,speed,bytes in 
                        
                    },
                    completion: { image, error, fromCache, fromStorage in
                        if let image = image {
                            // TODO
                        } else {
                            // TODO
                        }
                    }
                )
                if let image = image {
                    _ = self.storageAgent.saveImage(image, for: url)
                    await self.cacheAgent.setImage(image,
                                                   for: url,
                                                   isHighLatency: latency.isHighLatency)
                    // TODO
                    notifyCaller(caller: caller)
                }
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
            updateLatency: .high,
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
    ) -> UIImage? {
        // Convert DownloadProgress to simple CGFloat for backward compatibility
        let progressAdapter: DownloadProgressHandler? = progress.map { progressBlock in
            return { downloadProgress in
                DispatchQueue.main.async {
                    progressBlock(CGFloat(downloadProgress.progress), CGFloat(downloadProgress.speed), CGFloat(downloadProgress.bytesDownloaded))
                }
            }
        }

        // Step 1: Download raw data from network
        networkAgent.downloadData(at: url, priority: downloadPriority, progress: progressAdapter) { data, error in
            // Handle error
            if let error = error {
                DispatchQueue.main.async {
                    completion?(nil, error, false, false)
                }
                return
            }

            // Step 2: Decode data to UIImage
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?(nil, ImageDownloaderError.unknown(
                        NSError(domain: "ImageDownloader", code: -1, userInfo: nil)
                    ), false, false)
                }
                return
            }

            // Decode on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = ImageDecoder.decodeImage(from: data) else {
                    DispatchQueue.main.async {
                        completion?(nil, ImageDownloaderError.decodingFailed, false, false)
                    }
                    return
                }

                // Step 3: Notify completion on main thread
                DispatchQueue.main.async {
                    completion?(image, nil, false, false)
                }
            }
        }

        return nil
    }
}
