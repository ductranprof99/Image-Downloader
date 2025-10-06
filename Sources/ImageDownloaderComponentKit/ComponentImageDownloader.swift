//
//  ComponentImageDownloader.swift
//  ImageDownloaderComponentKit
//
//  Bridge between CKNetworkImageComponent and ImageDownloaderManager
//  Converted from Objective-C++ to Swift
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif
import ComponentKit
import ImageDownloader

/// Bridge between CKNetworkImageComponent and ImageDownloaderManager
///
/// Exposes full ImageDownloader capabilities:
/// - Cache priority control (high/low)
/// - Disk storage configuration
/// - Progress tracking
/// - Completion callbacks with cache/storage info
@objc public class ComponentImageDownloader: NSObject, CKNetworkImageDownloading {

    // MARK: - Properties

    private var downloadTokens: [String: URL] = [:]
    private let tokensLock = NSLock()
    private let priority: ResourcePriority
    private let shouldSaveToStorage: Bool
    private let userProgressBlock: ((CGFloat) -> Void)?
    private let userCompletionBlock: ((UIImage?, Error?, Bool) -> Void)?

    // MARK: - Factory Methods

    /// Create downloader with full ImageDownloader configuration
    ///
    /// - Parameters:
    ///   - priority: Cache priority (.high or .low)
    ///   - shouldSave: Whether to save downloaded image to disk storage
    ///   - progressBlock: Progress callback (0.0 to 1.0) - called on main queue
    ///   - completionBlock: Completion callback with cache/storage info - called on main queue
    @objc public static func downloader(
        priority: ResourcePriority,
        shouldSaveToStorage shouldSave: Bool,
        onProgress progressBlock: ((CGFloat) -> Void)?,
        onCompletion completionBlock: ((UIImage?, Error?, Bool) -> Void)?
    ) -> ComponentImageDownloader {
        return ComponentImageDownloader(
            priority: priority,
            shouldSaveToStorage: shouldSave,
            progressBlock: progressBlock,
            completionBlock: completionBlock
        )
    }

    /// Convenience: Create default downloader (low priority, saves to storage)
    @objc public static func downloader() -> ComponentImageDownloader {
        return downloader(
            priority: .low,
            shouldSaveToStorage: true,
            onProgress: nil,
            onCompletion: nil
        )
    }

    /// Convenience: Create downloader with priority control
    @objc public static func downloader(priority: ResourcePriority) -> ComponentImageDownloader {
        return downloader(
            priority: priority,
            shouldSaveToStorage: true,
            onProgress: nil,
            onCompletion: nil
        )
    }

    /// Convenience: Create downloader with progress tracking
    @objc public static func downloader(
        progressBlock: @escaping (CGFloat) -> Void
    ) -> ComponentImageDownloader {
        return downloader(
            priority: .low,
            shouldSaveToStorage: true,
            onProgress: progressBlock,
            onCompletion: nil
        )
    }

    // MARK: - Initialization

    private init(
        priority: ResourcePriority,
        shouldSaveToStorage: Bool,
        progressBlock: ((CGFloat) -> Void)?,
        completionBlock: ((UIImage?, Error?, Bool) -> Void)?
    ) {
        self.priority = priority
        self.shouldSaveToStorage = shouldSaveToStorage
        self.userProgressBlock = progressBlock
        self.userCompletionBlock = completionBlock
        super.init()
    }

    // MARK: - CKNetworkImageDownloading Protocol

    @objc public func downloadImage(
        with url: URL,
        caller: Any,
        callbackQueue: DispatchQueue,
        downloadProgressBlock: ((CGFloat) -> Void)?,
        completion: @escaping (CGImage?, Error?) -> Void
    ) -> Any {
        // Generate unique token for this download
        let token = generateToken(for: url)

        tokensLock.lock()
        downloadTokens[token] = url
        tokensLock.unlock()

        // Combine CKNetworkImageComponent's progress with user's progress block
        let combinedProgressBlock: ((CGFloat) -> Void)? = { [weak self] progress in
            // Call CKNetworkImageComponent's progress block
            if let downloadProgressBlock = downloadProgressBlock {
                callbackQueue.async {
                    downloadProgressBlock(progress)
                }
            }

            // Call user's custom progress block
            if let userProgress = self?.userProgressBlock {
                DispatchQueue.main.async {
                    userProgress(progress)
                }
            }
        }

        // Request image from ImageDownloaderManager with configured settings
        ImageDownloaderManager.shared.requestImage(
            at: url,
            priority: priority,
            shouldSaveToStorage: shouldSaveToStorage,
            progress: combinedProgressBlock,
            completion: { [weak self] image, error, fromCache, fromStorage in
                // Call CKNetworkImageComponent's completion block
                let cgImage = image?.cgImage
                callbackQueue.async {
                    completion(cgImage, error)
                }

                // Call user's custom completion block on main queue
                if let userCompletion = self?.userCompletionBlock {
                    DispatchQueue.main.async {
                        userCompletion(image, error, fromCache || fromStorage)
                    }
                }

                // Clean up token
                self?.tokensLock.lock()
                self?.downloadTokens.removeValue(forKey: token)
                self?.tokensLock.unlock()
            },
            caller: caller as AnyObject
        )

        return token
    }

    @objc public func cancelImageDownload(_ download: Any) {
        guard let token = download as? String else {
            return
        }

        tokensLock.lock()
        let url = downloadTokens[token]
        if url != nil {
            downloadTokens.removeValue(forKey: token)
        }
        tokensLock.unlock()

        if let url = url {
            ImageDownloaderManager.shared.cancelRequest(for: url, caller: self)
        }
    }

    // MARK: - Private Helpers

    private func generateToken(for url: URL) -> String {
        // Use timestamp + random for better uniqueness
        let timestamp = Date().timeIntervalSince1970
        let random = arc4random_uniform(10000)
        return "\(url.absoluteString)_\(Int(timestamp * 1000))_\(random)"
    }
}
