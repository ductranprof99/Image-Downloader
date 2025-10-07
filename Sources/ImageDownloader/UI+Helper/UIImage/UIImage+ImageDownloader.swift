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
    
    // MARK: - Image Transformation
    
    /// Resize image to specified size while maintaining aspect ratio
    /// - Parameter size: Target size
    /// - Returns: Resized image
    @objc public func resizedImage(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Compress image with specified quality
    /// - Parameter quality: Compression quality (0.0 to 1.0)
    /// - Returns: Compressed image data
    @objc public func compressedData(quality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    // MARK: - Async/Await API (Modern Swift)

    /// Load image from URL with optional custom configuration
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    /// - Returns: The loaded UIImage
    /// - Throws: ImageDownloaderError if loading fails
    public static func load(
        from url: URL,
        config: IDConfiguration? = nil,
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
    public static func load(
        from urlString: String,
        config: IDConfiguration? = nil,
        priority: ResourcePriority = .low
    ) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ImageDownloaderError.invalidURLUnknown
        }
        return try await load(from: url, config: config, priority: priority)
    }

    // MARK: - Cache Management
    /// Preload image into cache
    /// - Parameters:
    ///   - url: The URL to preload
    ///   - priority: Download priority (default: .low)
    @objc public static func preloadImage(from url: URL, priority: ResourcePriority = .low) {
        load(from: url, priority: priority) { _ in }
    }
    

    // MARK: - Completion Handler API (Compatible with all iOS versions)
    
    /// Load image from URL with completion handler (Objective-C compatible)
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    ///   - progress: Progress callback (0.0 to 1.0)
    ///   - completion: Completion callback with image or error
    @objc public static func loadImage(
        from url: URL,
        config: IDConfiguration? = nil,
        priority: ResourcePriority = .low,
        progress: ((CGFloat) -> Void)? = nil,
        completion: @escaping (UIImage?, NSError?) -> Void
    ) {
        let manager = ImageDownloaderManager.instance(for: config)
        manager.requestImage(
            at: url,
            priority: priority,
            progress: progress
        ) { image, error, _, _ in
            completion(image, error as NSError?)
        }
    }
    
    /// Load image from URL with Result type (Swift-friendly)
    /// - Parameters:
    ///   - url: The URL to load from
    ///   - config: Custom configuration (nil = use default)
    ///   - priority: Download priority (default: .normal)
    ///   - progress: Progress callback (0.0 to 1.0)
    ///   - completion: Completion callback with Result type
    public static func load(
        from url: URL,
        config: IDConfiguration? = nil,
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
        config: IDConfiguration? = nil,
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
