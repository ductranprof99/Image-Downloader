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
            // Step 1: Check cache
            let cacheResult = await self.cacheAgent.image(for: url)
            switch cacheResult {
            case .hit(let image):
                // Cache hit - return immediately
                mainThreadCompletion?(image, nil, true, false)

            case .wait:
                // Another request is already downloading - register as waiter
                if let completion = mainThreadCompletion {
                    registerCaller(url: url, caller: caller, completion: completion, progress: progress)
                }
                return

            case .miss:
                // Cache miss - download from network
                downloadFromNetworkThenUpdate(
                    at: url,
                    downloadPriority: downloadPriority,
                    latency: latency,
                    progress: progress,
                    completion: mainThreadCompletion
                )
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
        latency: ResourceUpdateLatency,
        progress: ImageProgressBlock? = nil,
        completion: ImageCompletionBlock? = nil
    ) {
        // Convert DownloadProgress to simple CGFloat for backward compatibility
        let progressAdapter: DownloadProgressHandler? = progress.map { progressBlock in
            return { downloadProgress in
                DispatchQueue.main.async {
                    progressBlock(CGFloat(downloadProgress.progress), CGFloat(downloadProgress.speed), CGFloat(downloadProgress.bytesDownloaded))
                }
            }
        }

        // Download and decode image from network (NetworkAgent now returns UIImage)
        networkAgent.downloadData(at: url, priority: downloadPriority, progress: progressAdapter) { [weak self] image, error in
            guard let self = self else { return }

            // Handle error
            if let error = error {
                self.notifyFailure(url: url, error: error, completion: completion)
                return
            }

            // Validate image
            guard let image = image else {
                let error = ImageDownloaderError.unknown(
                    NSError(domain: "ImageDownloader", code: -1, userInfo: nil)
                )
                self.notifyFailure(url: url, error: error, completion: completion)
                return
            }

            // Process downloaded image: save to storage, update cache, notify
            self.processDownloadedImage(image, url: url, latency: latency, completion: completion)
        }
    }

    /// Process downloaded image: save to storage, update cache, notify
    private func processDownloadedImage(
        _ image: UIImage,
        url: URL,
        latency: ResourceUpdateLatency,
        completion: ImageCompletionBlock?
    ) {
        // Save to storage on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Save to storage
            _ = self.storageAgent.saveImage(image, for: url)

            // Update cache and notify
            Task {
                await self.cacheAgent.setImage(image, for: url, isHighLatency: latency.isHighLatency)
                self.notifySuccess(url: url, image: image, completion: completion)
            }
        }
    }

    /// Notify success on main thread
    private func notifySuccess(url: URL, image: UIImage, completion: ImageCompletionBlock?) {
        DispatchQueue.main.async {
            // Notify original caller first
            completion?(image, nil, false, false)

            // Notify all waiting callers
            self.notifyCallers(
                url: url,
                image: image,
                error: nil,
                fromCache: false,
                fromStorage: false
            )
        }
    }

    /// Notify failure on main thread
    private func notifyFailure(url: URL, error: Error, completion: ImageCompletionBlock?) {
        DispatchQueue.main.async {
            // Notify original caller first
            completion?(nil, error, false, false)

            // Notify all waiting callers
            self.notifyCallers(
                url: url,
                image: nil,
                error: error,
                fromCache: false,
                fromStorage: false
            )
        }
    }
}
