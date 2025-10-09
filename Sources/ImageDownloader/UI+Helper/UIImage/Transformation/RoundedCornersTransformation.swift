//
//  RoundedCornersTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


import UIKit
import Foundation
// MARK: - Rounded Corners Transformation

/// Adds rounded corners to image
public class RoundedCornersTransformation: ImageTransformation {

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
