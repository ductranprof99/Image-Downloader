//
//  UIImageView+ImageDownloader.swift
//  ImageDownloaderUI
//
//  Convenience extension for adding image loading to any UIImageView
//

#if canImport(UIKit)
import UIKit
#endif

import ObjectiveC

/// Extension on UIImageView for convenient image loading
///
/// Adds image loading capabilities to any UIImageView without subclassing.
/// Uses associated objects to track loading state.
///
/// Example usage:
/// ```swift
/// let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
/// imageView.setImage(
///     with: URL(string: "https://example.com/image.jpg")!,
///     placeholder: UIImage(named: "placeholder")
/// )
/// ```
public extension UIImageView {

    // MARK: - Associated Object Keys

    
}
