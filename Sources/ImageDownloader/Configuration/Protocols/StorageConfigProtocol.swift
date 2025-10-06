//
//  StorageConfigProtocol.swift
//  ImageDownloader
//
//  Storage configuration protocol for injectable config system
//

import Foundation

/// Protocol defining storage-related configuration
public protocol StorageConfigProtocol {

    // MARK: - Basic Settings

    /// Whether to save images to disk storage by default (default: true)
    var shouldSaveToStorage: Bool { get }

    /// Custom storage path (nil = default Caches directory)
    var storagePath: String? { get }

    // MARK: - Customization Providers

    /// Resource identifier provider (default: MD5IdentifierProvider)
    var identifierProvider: any ResourceIdentifierProvider { get }

    /// Storage path provider (default: FlatStoragePathProvider)
    var pathProvider: any StoragePathProvider { get }

    /// Image compression provider (default: PNGCompressionProvider)
    var compressionProvider: any ImageCompressionProvider { get }
}

// MARK: - Default Implementation

extension StorageConfigProtocol {
    public var shouldSaveToStorage: Bool { true }
    public var storagePath: String? { nil }
    public var identifierProvider: any ResourceIdentifierProvider { MD5IdentifierProvider() }
    public var pathProvider: any StoragePathProvider { FlatStoragePathProvider() }
    public var compressionProvider: any ImageCompressionProvider { PNGCompressionProvider() }
}
