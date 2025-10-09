//
//  ImageTransformation.swift
//  ImageDownloader
//
//  Provides image transformation capabilities (resize, aspect, crop, etc.)
//

import UIKit
import Foundation

// MARK: - Convenience Extensions
public extension UIImage {

    /// Apply a transformation to this image
    func applying(_ transformation: ImageTransformation) -> UIImage? {
        return transformation.transform(self)
    }

    /// Resize image to target size
    func resized(to size: CGSize, contentMode: UIView.ContentMode = .scaleAspectFill) -> UIImage? {
        return ResizeTransformation(targetSize: size, contentMode: contentMode).transform(self)
    }

    /// Crop image to rect
    func cropped(to rect: CGRect) -> UIImage? {
        return CropTransformation(cropRect: rect).transform(self)
    }

    /// Add rounded corners
    func withRoundedCorners(radius: CGFloat, targetSize: CGSize? = nil) -> UIImage? {
        return RoundedCornersTransformation(cornerRadius: radius, targetSize: targetSize).transform(self)
    }

    /// Make circular
    func circularImage(diameter: CGFloat? = nil) -> UIImage? {
        return CircleTransformation(diameter: diameter).transform(self)
    }

    /// Maintain aspect ratio
    func withAspectRatio(_ ratio: CGFloat, fillMode: AspectRatioTransformation.FillMode = .fill) -> UIImage? {
        return AspectRatioTransformation(aspectRatio: ratio, fillMode: fillMode).transform(self)
    }
}
