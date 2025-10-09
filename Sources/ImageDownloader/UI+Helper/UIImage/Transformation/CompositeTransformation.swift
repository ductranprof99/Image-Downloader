//
//  CompositeTransformation.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//


import UIKit
import Foundation

// MARK: - Composite Transformation

/// Applies multiple transformations in sequence
public class CompositeTransformation: ImageTransformation {

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