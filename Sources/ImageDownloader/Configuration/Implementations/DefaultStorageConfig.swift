//
//  DefaultStorageConfig.swift
//  ImageDownloader
//
//  Default storage configuration implementation
//

import Foundation

/// Default storage configuration with standard settings
public struct DefaultStorageConfig: StorageConfigProtocol {
    public var shouldSaveToStorage: Bool
    public var storagePath: String?
    public var identifierProvider: any ResourceIdentifierProvider
    public var pathProvider: any StoragePathProvider
    public var compressionProvider: any ImageCompressionProvider

    public init(
        shouldSaveToStorage: Bool = true,
        storagePath: String? = nil,
        identifierProvider: any ResourceIdentifierProvider = MD5IdentifierProvider(),
        pathProvider: any StoragePathProvider = FlatStoragePathProvider(),
        compressionProvider: any ImageCompressionProvider = PNGCompressionProvider()
    ) {
        self.shouldSaveToStorage = shouldSaveToStorage
        self.storagePath = storagePath
        self.identifierProvider = identifierProvider
        self.pathProvider = pathProvider
        self.compressionProvider = compressionProvider
    }
}
