//
//  ImageResult.swift
//  ImageDownloader
//
//  Result types for image download operations
//

import Foundation
import UIKit

/// Result of an image download operation (Swift-only)
public struct ImageResult {
    public let image: UIImage
    public let url: URL
    public let fromCache: Bool
    public let fromStorage: Bool

    public init(image: UIImage, url: URL, fromCache: Bool, fromStorage: Bool) {
        self.image = image
        self.url = url
        self.fromCache = fromCache
        self.fromStorage = fromStorage
    }
}
