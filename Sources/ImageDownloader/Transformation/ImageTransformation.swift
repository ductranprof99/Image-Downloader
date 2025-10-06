//
//  ImageTransformation.swift
//  ImageDownloader
//
//  Provides image transformation capabilities (resize, aspect, crop, etc.)
//

#if canImport(UIKit)
import UIKit
#endif
import Foundation

// MARK: - Image Transformation Protocol

/// Protocol for image transformations
public protocol ImageTransformation {
    /// Transform the given image
    /// - Parameter image: The source image
    /// - Returns: The transformed image, or nil if transformation fails
    func transform(_ image: UIImage) -> UIImage?

    /// Unique identifier for this transformation (used for caching)
    var identifier: String { get }
}

// MARK: - Resize Transformation

/// Resizes image to target size
public struct ResizeTransformation: ImageTransformation {

    public let targetSize: CGSize
    public let contentMode: UIView.ContentMode

    public init(targetSize: CGSize, contentMode: UIView.ContentMode = .scaleAspectFill) {
        self.targetSize = targetSize
        self.contentMode = contentMode
    }

    public var identifier: String {
        return "resize_\(Int(targetSize.width))x\(Int(targetSize.height))_\(contentMode.rawValue)"
    }

    public func transform(_ image: UIImage) -> UIImage? {
        let size = calculateSize(for: image.size, targetSize: targetSize, contentMode: contentMode)

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func calculateSize(for imageSize: CGSize, targetSize: CGSize, contentMode: UIView.ContentMode) -> CGSize {
        switch contentMode {
        case .scaleAspectFit:
            return aspectFitSize(imageSize: imageSize, targetSize: targetSize)
        case .scaleAspectFill:
            return aspectFillSize(imageSize: imageSize, targetSize: targetSize)
        case .scaleToFill:
            return targetSize
        default:
            return targetSize
        }
    }

    private func aspectFitSize(imageSize: CGSize, targetSize: CGSize) -> CGSize {
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)

        return CGSize(
            width: imageSize.width * ratio,
            height: imageSize.height * ratio
        )
    }

    private func aspectFillSize(imageSize: CGSize, targetSize: CGSize) -> CGSize {
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = max(widthRatio, heightRatio)

        return CGSize(
            width: imageSize.width * ratio,
            height: imageSize.height * ratio
        )
    }
}

// MARK: - Crop Transformation

/// Crops image to target rect
public struct CropTransformation: ImageTransformation {

    public let cropRect: CGRect

    public init(cropRect: CGRect) {
        self.cropRect = cropRect
    }

    public var identifier: String {
        return "crop_\(Int(cropRect.origin.x))_\(Int(cropRect.origin.y))_\(Int(cropRect.width))_\(Int(cropRect.height))"
    }

    public func transform(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let scaledRect = CGRect(
            x: cropRect.origin.x * image.scale,
            y: cropRect.origin.y * image.scale,
            width: cropRect.width * image.scale,
            height: cropRect.height * image.scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Rounded Corners Transformation

/// Adds rounded corners to image
public struct RoundedCornersTransformation: ImageTransformation {

    public let cornerRadius: CGFloat
    public let targetSize: CGSize?

    public init(cornerRadius: CGFloat, targetSize: CGSize? = nil) {
        self.cornerRadius = cornerRadius
        self.targetSize = targetSize
    }

    public var identifier: String {
        if let size = targetSize {
            return "rounded_\(Int(cornerRadius))_\(Int(size.width))x\(Int(size.height))"
        } else {
            return "rounded_\(Int(cornerRadius))"
        }
    }

    public func transform(_ image: UIImage) -> UIImage? {
        let size = targetSize ?? image.size

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.addClip()

        image.draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Circle Transformation

/// Crops image to circle
public struct CircleTransformation: ImageTransformation {

    public let diameter: CGFloat?

    public init(diameter: CGFloat? = nil) {
        self.diameter = diameter
    }

    public var identifier: String {
        if let diameter = diameter {
            return "circle_\(Int(diameter))"
        } else {
            return "circle"
        }
    }

    public func transform(_ image: UIImage) -> UIImage? {
        let size: CGSize
        if let diameter = diameter {
            size = CGSize(width: diameter, height: diameter)
        } else {
            let minDimension = min(image.size.width, image.size.height)
            size = CGSize(width: minDimension, height: minDimension)
        }

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(ovalIn: rect)
        path.addClip()

        // Center image
        let imageRect = CGRect(
            x: (size.width - image.size.width) / 2,
            y: (size.height - image.size.height) / 2,
            width: image.size.width,
            height: image.size.height
        )
        image.draw(in: imageRect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Aspect Ratio Transformation

/// Maintains aspect ratio and fills target size
public struct AspectRatioTransformation: ImageTransformation {

    public let aspectRatio: CGFloat
    public let fillMode: FillMode

    public enum FillMode {
        case fit    // Fit entire image within aspect ratio
        case fill   // Fill aspect ratio, cropping if needed
    }

    public init(aspectRatio: CGFloat, fillMode: FillMode = .fill) {
        self.aspectRatio = aspectRatio
        self.fillMode = fillMode
    }

    public var identifier: String {
        let ratio = String(format: "%.2f", aspectRatio)
        return "aspect_\(ratio)_\(fillMode == .fit ? "fit" : "fill")"
    }

    public func transform(_ image: UIImage) -> UIImage? {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height

        let targetSize: CGSize
        switch fillMode {
        case .fit:
            if imageAspectRatio > aspectRatio {
                // Image is wider
                targetSize = CGSize(
                    width: imageSize.width,
                    height: imageSize.width / aspectRatio
                )
            } else {
                // Image is taller
                targetSize = CGSize(
                    width: imageSize.height * aspectRatio,
                    height: imageSize.height
                )
            }
        case .fill:
            if imageAspectRatio > aspectRatio {
                // Image is wider, crop width
                targetSize = CGSize(
                    width: imageSize.height * aspectRatio,
                    height: imageSize.height
                )
            } else {
                // Image is taller, crop height
                targetSize = CGSize(
                    width: imageSize.width,
                    height: imageSize.width / aspectRatio
                )
            }
        }

        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Composite Transformation

/// Applies multiple transformations in sequence
public struct CompositeTransformation: ImageTransformation {

    public let transformations: [ImageTransformation]

    public init(transformations: [ImageTransformation]) {
        self.transformations = transformations
    }

    public var identifier: String {
        return transformations.map { $0.identifier }.joined(separator: "_")
    }

    public func transform(_ image: UIImage) -> UIImage? {
        var result: UIImage? = image

        for transformation in transformations {
            guard let currentImage = result else { return nil }
            result = transformation.transform(currentImage)
        }

        return result
    }
}

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
