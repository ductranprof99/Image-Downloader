//
//  CropTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//

import UIKit
import Foundation

// MARK: - Crop Transformation

/// Crops image to target rect
public class CropTransformation: ImageTransformation {

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
