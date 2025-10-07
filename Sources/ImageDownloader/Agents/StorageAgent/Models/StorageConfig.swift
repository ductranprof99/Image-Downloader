//
//  StorageConfig.swift
//  ImageDownloader
//
//  Internal storage configuration implementation
//

import Foundation

/// Internal storage configuration with standard settings
struct StorageConfig {
    var shouldSaveToStorage: Bool
    var storagePath: String?
    var identifierProvider: any ResourceIdentifierProvider
    var pathProvider: any StoragePathProvider
    var compressionProvider: any ImageCompressionProvider

    // Default initializer
    init(
        shouldSaveToStorage: Bool = true,
        storagePath: String? = nil,
        identifierProvider: any ResourceIdentifierProvider = MD5IdentifierProvider(),
        pathProvider: any StoragePathProvider = FlatHierarchicalPathProvider(),
        compressionProvider: any ImageCompressionProvider = PNGCompressionProvider()
    ) {
        self.shouldSaveToStorage = shouldSaveToStorage
        self.storagePath = storagePath
        self.identifierProvider = identifierProvider
        self.pathProvider = pathProvider
        self.compressionProvider = compressionProvider
    }
}
