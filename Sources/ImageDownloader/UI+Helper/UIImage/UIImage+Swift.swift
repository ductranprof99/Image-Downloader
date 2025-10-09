//
//  UIImage+Swift.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//

import UIKit

extension UIImage {
    // MARK: - Async/Await API (Modern Swift)
    /// Load image from URL string with optional custom configuration
    /// - Parameters:
    ///   - urlString: The URL string to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    /// - Returns: The loaded UIImage
    /// - Throws: ImageDownloaderError if loading fails or URL is invalid
    public static func load(
        from urlString: String,
        config: IDConfiguration? = nil,
        manager: ImageDownloaderManager? = nil,
        priority: DownloadPriority = .low
    ) async throws -> UIImage {
        // TODO
    }



    /// Load image from URL string with completion handler
    /// - Parameters:
    ///   - urlString: The URL string to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    ///   - progress: Progress callback (0.0 to 1.0)
    ///   - completion: Completion callback with image or error
    public static func load(
        from urlString: String,
        config: IDConfiguration? = nil,
        manager: ImageDownloaderManager? = nil,
        downloadPriority: DownloadPriority = .low,
        progress: ((CGFloat, CGFloat, CGFloat) -> Void)? = nil,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        
    }
}
