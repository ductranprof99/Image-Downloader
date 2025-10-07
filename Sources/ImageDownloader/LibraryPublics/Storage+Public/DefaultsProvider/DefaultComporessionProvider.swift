//
//  DefaultProviders.swift
//  ImageDownloader
//
//  Default implementations of customization protocols
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Default Compression Providers

/// PNG compression provider (lossless, backward compatible)
public class PNGCompressionProvider: ImageCompressionProvider {
    public init() {}

    public func compress(_ image: UIImage) -> Data? {
        return image.pngData()
    }

    public func decompress(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }

    public var fileExtension: String {
        return "png"
    }

    public var name: String {
        return "PNG (Lossless)"
    }
}

/// JPEG compression provider (lossy, saves space)
public class JPEGCompressionProvider: ImageCompressionProvider {
    public let quality: CGFloat

    /// Initialize with compression quality
    /// - Parameter quality: Compression quality (0.0 = maximum compression, 1.0 = maximum quality)
    public init(quality: CGFloat = 0.8) {
        self.quality = min(max(quality, 0.0), 1.0)  // Clamp to [0.0, 1.0]
    }

    public func compress(_ image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }

    public func decompress(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }

    public var fileExtension: String {
        return "jpg"
    }

    public var name: String {
        return "JPEG (Quality: \(Int(quality * 100))%)"
    }
}

/// Adaptive compression provider (chooses PNG or JPEG based on size)
public class AdaptiveCompressionProvider: ImageCompressionProvider {
    public let sizeThresholdMB: Double
    public let jpegQuality: CGFloat

    private let pngProvider: PNGCompressionProvider
    private let jpegProvider: JPEGCompressionProvider

    /// Initialize with size threshold
    /// - Parameters:
    ///   - sizeThresholdMB: Size threshold in megabytes (default: 1.0 MB)
    ///   - jpegQuality: JPEG compression quality when threshold is exceeded (default: 0.8)
    public init(sizeThresholdMB: Double = 1.0, jpegQuality: CGFloat = 0.8) {
        self.sizeThresholdMB = sizeThresholdMB
        self.jpegQuality = jpegQuality
        self.pngProvider = PNGCompressionProvider()
        self.jpegProvider = JPEGCompressionProvider(quality: jpegQuality)
    }

    public func compress(_ image: UIImage) -> Data? {
        // Try PNG first
        guard let pngData = pngProvider.compress(image) else { return nil }

        let sizeInMB = Double(pngData.count) / (1024 * 1024)

        // If too large, use JPEG
        if sizeInMB > sizeThresholdMB {
            return jpegProvider.compress(image)
        }

        return pngData
    }

    public func decompress(_ data: Data) -> UIImage? {
        return UIImage(data: data)  // UIKit handles both PNG and JPEG
    }

    public var fileExtension: String {
        return "auto"  // Could be PNG or JPEG
    }

    public var name: String {
        return "Adaptive (PNG < \(sizeThresholdMB)MB, else JPEG \(Int(jpegQuality * 100))%)"
    }
}
