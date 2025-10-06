//
//  Protocols.swift
//  ImageDownloader
//
//  Protocol definitions for customization system
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Resource Identifier Provider

/// Protocol for generating unique identifiers for resources
public protocol ResourceIdentifierProvider {
    /// Generate a unique identifier for the given URL
    /// - Parameter url: The resource URL
    /// - Returns: A unique identifier string (used for cache keys and file naming)
    func identifier(for url: URL) -> String
}

// MARK: - Storage Path Provider

/// Protocol for determining storage paths for resources
public protocol StoragePathProvider {
    /// Generate the relative file path for storing a resource
    /// - Parameters:
    ///   - url: The resource URL
    ///   - identifier: The unique identifier for this resource
    /// - Returns: Relative path within the storage directory (e.g., "images/abc123.png")
    func path(for url: URL, identifier: String) -> String

    /// Get the directory structure (subdirectories) for organizing storage
    /// - Parameter url: The resource URL
    /// - Returns: Array of subdirectory names (e.g., ["images", "2025"] for "images/2025/file.png")
    func directoryStructure(for url: URL) -> [String]
}

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

// MARK: - Type-Erased Wrappers for Objective-C Compatibility

/// Type-erased wrapper for ResourceIdentifierProvider (Objective-C compatible)
@objc public class AnyResourceIdentifierProvider: NSObject {
    private let _identifier: (URL) -> String

    public init<T: ResourceIdentifierProvider>(_ provider: T) {
        self._identifier = provider.identifier
        super.init()
    }

    @objc public func identifier(for url: URL) -> String {
        return _identifier(url)
    }
}

/// Type-erased wrapper for StoragePathProvider (Objective-C compatible)
@objc public class AnyStoragePathProvider: NSObject {
    private let _path: (URL, String) -> String
    private let _directoryStructure: (URL) -> [String]

    public init<T: StoragePathProvider>(_ provider: T) {
        self._path = provider.path
        self._directoryStructure = provider.directoryStructure
        super.init()
    }

    @objc public func path(for url: URL, identifier: String) -> String {
        return _path(url, identifier)
    }

    @objc public func directoryStructure(for url: URL) -> [String] {
        return _directoryStructure(url)
    }
}

/// Type-erased wrapper for ImageCompressionProvider (Objective-C compatible)
@objc public class AnyImageCompressionProvider: NSObject {
    private let _compress: (UIImage) -> Data?
    private let _decompress: (Data) -> UIImage?
    private let _fileExtension: String
    private let _name: String

    public init<T: ImageCompressionProvider>(_ provider: T) {
        self._compress = provider.compress
        self._decompress = provider.decompress
        self._fileExtension = provider.fileExtension
        self._name = provider.name
        super.init()
    }

    @objc public func compress(_ image: UIImage) -> Data? {
        return _compress(image)
    }

    @objc public func decompress(_ data: Data) -> UIImage? {
        return _decompress(data)
    }

    @objc public var fileExtension: String {
        return _fileExtension
    }

    @objc public var name: String {
        return _name
    }
}
