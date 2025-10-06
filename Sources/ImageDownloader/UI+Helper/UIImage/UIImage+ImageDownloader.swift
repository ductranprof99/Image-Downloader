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

    // MARK: - Async/Await API (Modern Swift)

    /// Load image from URL with optional custom configuration
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    /// - Returns: The loaded UIImage
    /// - Throws: ImageDownloaderError if loading fails
    @available(iOS 13.0, macOS 10.15, *)
    public static func load(
        from url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .low
    ) async throws -> UIImage {
        let manager = ImageDownloaderManager.instance(for: config)
        let result = try await manager.requestImage(at: url, priority: priority)
        return result.image
    }

    /// Load image from URL string with optional custom configuration
    /// - Parameters:
    ///   - urlString: The URL string to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    /// - Returns: The loaded UIImage
    /// - Throws: ImageDownloaderError if loading fails or URL is invalid
    @available(iOS 13.0, macOS 10.15, *)
    public static func load(
        from urlString: String,
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .low
    ) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ImageDownloaderError.invalidURLUnknown
        }
        return try await load(from: url, config: config, priority: priority)
    }

    // MARK: - Completion Handler API (Compatible with all iOS versions)

    /// Load image from URL with completion handler
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    ///   - progress: Progress callback (0.0 to 1.0)
    ///   - completion: Completion callback with image or error
    public static func load(
        from url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .low,
        progress: ((CGFloat) -> Void)? = nil,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let manager = ImageDownloaderManager.instance(for: config)
        manager.requestImage(
            at: url,
            priority: priority,
            progress: progress
        ) { image, error, _, _ in
            if let image = image {
                completion(.success(image))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(ImageDownloaderError.unknown(
                    NSError(domain: "ImageDownloader", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Unknown error occurred"
                    ])
                )))
            }
        }
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
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .low,
        progress: ((CGFloat) -> Void)? = nil,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(ImageDownloaderError.invalidURLUnknown))
            return
        }
        load(from: url, config: config, priority: priority, progress: progress, completion: completion)
    }
}

// MARK: - Error Extension

extension ImageDownloaderError {
    static var invalidURLUnknown: ImageDownloaderError {
        return .unknown(NSError(
            domain: "ImageDownloader",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Invalid URL string"]
        ))
    }
}

#endif
