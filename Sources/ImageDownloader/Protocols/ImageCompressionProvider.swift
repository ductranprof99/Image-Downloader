//
//  ImageCompressionProvider.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Image Compression Provider

/// Protocol for handling image compression and decompression
public protocol ImageCompressionProvider {
    /// Compress an image into data for storage
    /// - Parameter image: The image to compress
    /// - Returns: Compressed data, or nil if compression failed
    func compress(_ image: UIImage) -> Data?

    /// Decompress data back into an image
    /// - Parameter data: The compressed data
    /// - Returns: Decompressed image, or nil if decompression failed
    func decompress(_ data: Data) -> UIImage?

    /// File extension for compressed data (e.g., "png", "jpg", "webp")
    var fileExtension: String { get }

    /// Human-readable name for this compression format
    var name: String { get }
}
