//
//  AspectRatioTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


import UIKit
import Foundation

// MARK: - Aspect Ratio Transformation
/// Maintains aspect ratio and fills target size
public class AspectRatioTransformation: ImageTransformation {

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