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
import CryptoKit

// MARK: - Default Identifier Providers

/// Default identifier provider using MD5 hash (backward compatible)
public struct MD5IdentifierProvider: ResourceIdentifierProvider {
    public init() {}

    public func identifier(for url: URL) -> String {
        let urlString = url.absoluteString

        if #available(iOS 13.0, macOS 10.15, *) {
            let hash = Insecure.MD5.hash(data: Data(urlString.utf8))
            return hash.map { String(format: "%02x", $0) }.joined()
        } else {
            // Fallback for older OS versions
            return urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
        }
    }
}

/// SHA256 identifier provider (more secure, recommended for new projects)
@available(iOS 13.0, macOS 10.15, *)
public struct SHA256IdentifierProvider: ResourceIdentifierProvider {
    public init() {}

    public func identifier(for url: URL) -> String {
        let urlString = url.absoluteString
        let hash = SHA256.hash(data: Data(urlString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Default Storage Path Providers

/// Default flat storage provider (all files in single directory)
public struct FlatStoragePathProvider: StoragePathProvider {
    public init() {}

    public func path(for url: URL, identifier: String) -> String {
        let lastComponent = url.lastPathComponent
        if !lastComponent.isEmpty {
            // Sanitize filename
            let invalidChars = CharacterSet.alphanumerics.inverted
            let sanitized = lastComponent.components(separatedBy: invalidChars).joined(separator: "_")
            let limitedSanitized = String(sanitized.prefix(50))
            return "\(identifier)_\(limitedSanitized)"
        }

        // Fallback: just identifier with extension
        let extension_ = !url.pathExtension.isEmpty ? url.pathExtension : "png"
        return "\(identifier).\(extension_)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        return []  // No subdirectories
    }
}

/// Hierarchical storage by domain (e.g., "example.com/abc123.png")
public struct DomainHierarchicalPathProvider: StoragePathProvider {
    public init() {}

    public func path(for url: URL, identifier: String) -> String {
        let domain = url.host ?? "unknown"
        let ext = !url.pathExtension.isEmpty ? url.pathExtension : "png"
        return "\(domain)/\(identifier).\(ext)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        return [url.host ?? "unknown"]
    }
}

/// Hierarchical storage by date (e.g., "2025/10/06/abc123.png")
public struct DateHierarchicalPathProvider: StoragePathProvider {
    private let dateFormatter: DateFormatter

    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
    }

    public func path(for url: URL, identifier: String) -> String {
        let datePrefix = dateFormatter.string(from: Date())
        let ext = !url.pathExtension.isEmpty ? url.pathExtension : "png"
        return "\(datePrefix)/\(identifier).\(ext)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        let dateString = dateFormatter.string(from: Date())
        return dateString.components(separatedBy: "/")
    }
}

// MARK: - Default Compression Providers

/// PNG compression provider (lossless, backward compatible)
public struct PNGCompressionProvider: ImageCompressionProvider {
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
public struct JPEGCompressionProvider: ImageCompressionProvider {
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
public struct AdaptiveCompressionProvider: ImageCompressionProvider {
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

// MARK: - Objective-C Compatible Providers

/// Objective-C compatible MD5 identifier provider
@objc public class IDMD5IdentifierProvider: NSObject {
    private let provider = MD5IdentifierProvider()

    @objc public override init() {
        super.init()
    }

    @objc public func identifier(for url: URL) -> String {
        return provider.identifier(for: url)
    }
}

/// Objective-C compatible flat storage path provider
@objc public class IDFlatStoragePathProvider: NSObject {
    private let provider = FlatStoragePathProvider()

    @objc public override init() {
        super.init()
    }

    @objc public func path(for url: URL, identifier: String) -> String {
        return provider.path(for: url, identifier: identifier)
    }

    @objc public func directoryStructure(for url: URL) -> [String] {
        return provider.directoryStructure(for: url)
    }
}

/// Objective-C compatible domain hierarchical storage path provider
@objc public class IDDomainHierarchicalPathProvider: NSObject {
    private let provider = DomainHierarchicalPathProvider()

    @objc public override init() {
        super.init()
    }

    @objc public func path(for url: URL, identifier: String) -> String {
        return provider.path(for: url, identifier: identifier)
    }

    @objc public func directoryStructure(for url: URL) -> [String] {
        return provider.directoryStructure(for: url)
    }
}

/// Objective-C compatible PNG compression provider
@objc public class IDPNGCompressionProvider: NSObject {
    private let provider = PNGCompressionProvider()

    @objc public override init() {
        super.init()
    }

    @objc public func compress(_ image: UIImage) -> Data? {
        return provider.compress(image)
    }

    @objc public func decompress(_ data: Data) -> UIImage? {
        return provider.decompress(data)
    }

    @objc public var fileExtension: String {
        return provider.fileExtension
    }

    @objc public var name: String {
        return provider.name
    }
}

/// Objective-C compatible JPEG compression provider
@objc public class IDJPEGCompressionProvider: NSObject {
    private let provider: JPEGCompressionProvider

    @objc public init(quality: CGFloat = 0.8) {
        self.provider = JPEGCompressionProvider(quality: quality)
        super.init()
    }

    @objc public func compress(_ image: UIImage) -> Data? {
        return provider.compress(image)
    }

    @objc public func decompress(_ data: Data) -> UIImage? {
        return provider.decompress(data)
    }

    @objc public var fileExtension: String {
        return provider.fileExtension
    }

    @objc public var name: String {
        return provider.name
    }
}

/// Objective-C compatible adaptive compression provider
@objc public class IDAdaptiveCompressionProvider: NSObject {
    private let provider: AdaptiveCompressionProvider

    @objc public init(sizeThresholdMB: Double = 1.0, jpegQuality: CGFloat = 0.8) {
        self.provider = AdaptiveCompressionProvider(
            sizeThresholdMB: sizeThresholdMB,
            jpegQuality: jpegQuality
        )
        super.init()
    }

    @objc public func compress(_ image: UIImage) -> Data? {
        return provider.compress(image)
    }

    @objc public func decompress(_ data: Data) -> UIImage? {
        return provider.decompress(data)
    }

    @objc public var fileExtension: String {
        return provider.fileExtension
    }

    @objc public var name: String {
        return provider.name
    }
}
