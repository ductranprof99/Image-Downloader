//
//  ResizeTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


import UIKit

// MARK: - Resize Transformation
/// Resizes image to target size
public class ResizeTransformation: ImageTransformation {

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
