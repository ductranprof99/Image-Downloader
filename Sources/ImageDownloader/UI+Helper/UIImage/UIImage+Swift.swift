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
    ) async throws -> UIImage? {
        guard let url = URL(string: urlString) else {
            throw ImageDownloaderError.invalidURL
        }

        let manager = manager ?? (config == nil ? ImageDownloaderManager.shared : ImageDownloaderManager.instance(for: config))
//        let result = try await manager.requestImageAsync(at: url, downloadPriority: priority)
        return nil // result.image
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
        guard let url = URL(string: urlString) else {
            completion(.failure(ImageDownloaderError.invalidURL))
            return
        }

        let manager = manager ?? (config == nil ? ImageDownloaderManager.shared : ImageDownloaderManager.instance(for: config))

        manager.requestImage(
            at: url,
            downloadPriority: downloadPriority,
            progress: progress,
            completion: { image, error, _, _ in
                if let image = image {
                    completion(.success(image))
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(ImageDownloaderError.unknown(
                        NSError(domain: "ImageDownloader", code: -1, userInfo: nil)
                    )))
                }
            }
        )
    }
}
