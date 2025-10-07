//
//  IDMD5IdentifierProvider.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//


import Foundation
import UIKit

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

/// Objective-C compatible date hierarchical path provider
@objc public class IDDateHierarchicalPathProvider: NSObject {
    private let provider: DateHierarchicalPathProvider

    @objc public override init() {
        self.provider = DateHierarchicalPathProvider()
        super.init()
    }

    @objc public func path(for url: URL, identifier: String) -> String {
        return provider.path(for: url, identifier: identifier)
    }
}
