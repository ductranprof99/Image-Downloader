//
//  IDStorageConfig.swift
//  ImageDownloader
//
//  Objective-C compatible storage configuration
//

import Foundation

/// Objective-C compatible storage configuration class
@objc public class IDStorageConfig: NSObject {

    // MARK: - Basic Settings

    @objc public var shouldSaveToStorage: Bool
    @objc public var storagePath: String?

    // MARK: - Customization Providers (Objective-C wrappers)
    @objc public var identifierProvider: ResourceIdentifierProvider
    @objc public var pathProvider: StoragePathProvider
    @objc public var compressionProvider: ImageCompressionProvider


    // MARK: - Initialization

    @objc public init(
        shouldSaveToStorage: Bool = true,
        storagePath: String? = nil,
        identifierProvider: ResourceIdentifierProvider = MD5IdentifierProvider(),
        pathProvider: StoragePathProvider = FlatHierarchicalPathProvider(),
        compressionProvider: ImageCompressionProvider = PNGCompressionProvider()
    ) {
        self.shouldSaveToStorage = shouldSaveToStorage
        self.storagePath = storagePath
        self.identifierProvider = identifierProvider
        self.pathProvider = pathProvider
        self.compressionProvider = compressionProvider
        super.init()
    }

    // MARK: - Presets

    @objc public static func defaultConfig() -> IDStorageConfig {
        return IDStorageConfig()
    }

    @objc public static func defaultConfigWithPath(_ path: String) -> IDStorageConfig {
        return IDStorageConfig(storagePath: path)
    }
    
    // MARK: - Conversion

    func toInternalConfig() -> StorageConfig {
        return StorageConfig(
            shouldSaveToStorage: shouldSaveToStorage,
            storagePath: storagePath,
            identifierProvider: identifierProvider,
            pathProvider: pathProvider,
            compressionProvider: compressionProvider
        )
    }
}
