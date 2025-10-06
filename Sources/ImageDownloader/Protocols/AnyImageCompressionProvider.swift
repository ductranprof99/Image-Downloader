//
//  Protocols.swift
//  ImageDownloader
//
//  Protocol definitions for customization system
//

import UIKit

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
