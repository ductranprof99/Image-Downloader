//
//  CircleTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


import UIKit
import Foundation

// MARK: - Circle Transformation

/// Crops image to circle
public class CircleTransformation: ImageTransformation {

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
