//
//  UIImage+ImageDownloader.swift
//  ImageDownloader
//
//  UIImage extension for easy image loading with injectable config
//

#if canImport(UIKit)
import UIKit
import Foundation

extension UIImage {
    // MARK: - Completion Handler API (Compatible with all iOS versions)
    
    /// Load image from URL with completion handler (Objective-C compatible)
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - manager: Custom manager instance (nil = use shared or config-based instance)
    ///   - priority: Download priority (default: .low)
    ///   - progress: Progress callback (0.0 to 1.0)
    ///   - completion: Completion callback with image or error
    @objc public static func loadImageFromURL(
        _ url: URL,
        config: IDConfiguration? = nil,
        manager: ImageDownloaderManager? = nil,
        priority: DownloadPriority = .low,
        progress: ((_ progress: CGFloat, _ speed: CGFloat, _ bytes: CGFloat) -> Void)? = nil,
        completion: @escaping (UIImage?, NSError?) -> Void
    ) {
        let manager = manager ?? (config == nil ? ImageDownloaderManager.shared : ImageDownloaderManager.instance(for: config))

        manager.requestImage(
            at: url,
            downloadPriority: priority,
            progress: { prog, speed, bytes in
                progress?(prog, speed, bytes)
            },
            completion: { image, error, _, _ in
                completion(image, error as? NSError)
            }
        )
    }

    /// Convenient method without config/manager parameters
    @objc public static func loadImageFromURL(
        _ url: URL,
        completion: @escaping (UIImage?, NSError?) -> Void
    ) {
        loadImageFromURL(url, config: nil, manager: nil, priority: .low, progress: nil, completion: completion)
    }
}
#endif
