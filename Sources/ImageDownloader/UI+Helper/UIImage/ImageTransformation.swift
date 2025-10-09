//
//  ImageTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


import UIKit
import Foundation

// MARK: - Image Transformation Protocol

/// Protocol for image transformations
@objc public protocol ImageTransformation {
    /// Transform the given image
    /// - Parameter image: The source image
    /// - Returns: The transformed image, or nil if transformation fails
    func transform(_ image: UIImage) -> UIImage?

    /// Unique identifier for this transformation (used for caching)
    var identifier: String { get }
}
