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
    ///   - priority: Download priority (default: .normal)
    ///   - progress: Progress callback (0.0 to 1.0)
    ///   - completion: Completion callback with image or error
    @objc static func loadObjc(
        from url: URL,
        config: IDConfiguration? = nil,
        manager: ImageDownloaderManager? = nil,
        priority: DownloadPriority = .low,
        progress: ((CGFloat) -> Void)? = nil,
        completion: @escaping (UIImage?, NSError?) -> Void
    ) {
        let manager = manager ?? config == nil ? ImageDownloaderManager.shared : ImageDownloaderManager.instance(for: config)
        // TODO
        
    }
}
#endif
