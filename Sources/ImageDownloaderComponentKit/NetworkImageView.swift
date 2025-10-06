//
//  NetworkImageView.swift
//  ImageDownloaderComponentKit
//
//  Advanced network image component with full ImageDownloader integration
//  Converted from CustomNetworkImageView (removed "Custom" prefix)
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif
import ComponentKit
import ImageDownloader

/// Mask type for image views
@objc public enum ImageMaskType: Int {
    case none
    case circle
    case ellipse
    case rounded
}

/// Configuration for NetworkImageView
/// Provides full control over image loading, caching, and display
@objc public class NetworkImageViewOptions: NSObject {

    // MARK: - Display Options

    /// Placeholder image shown while loading or on error
    @objc public var placeholder: UIImage?

    /// Crop rectangle in unit coordinate space (0-1)
    @objc public var cropRect: CGRect = .zero

    /// Mask type for the image view
    @objc public var maskType: ImageMaskType = .none

    /// Corner radius (only used with .rounded mask type)
    @objc public var cornerRadius: CGFloat = 0.0

    // MARK: - Cache & Storage Options

    /// Cache priority - controls memory cache behavior
    @objc public var cachePriority: ResourcePriority = .low

    /// Whether to save downloaded image to disk storage
    @objc public var shouldSaveToStorage: Bool = true

    // MARK: - Progress & Completion

    /// Whether to show visual progress overlay (default: false)
    @objc public var progressOverlay: Bool = false

    /// Progress overlay background color (default: semi-transparent black)
    @objc public var progressBackgroundColor: UIColor?

    /// Progress overlay indicator color (default: white)
    @objc public var progressIndicatorColor: UIColor?

    /// Progress callback - reports download progress (0.0 to 1.0)
    @objc public var onProgress: ((CGFloat) -> Void)?

    /// Completion callback - called when image loads or fails
    /// Parameters: image, error, fromCache
    @objc public var onCompletion: ((UIImage?, Error?, Bool) -> Void)?

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    /// Convenience initializer with common options
    @objc public convenience init(
        placeholder: UIImage?,
        cachePriority: ResourcePriority = .low,
        shouldSaveToStorage: Bool = true
    ) {
        self.init()
        self.placeholder = placeholder
        self.cachePriority = cachePriority
        self.shouldSaveToStorage = shouldSaveToStorage
    }

    /// Convenience initializer with mask options
    @objc public convenience init(
        placeholder: UIImage?,
        maskType: ImageMaskType,
        cornerRadius: CGFloat = 0.0
    ) {
        self.init()
        self.placeholder = placeholder
        self.maskType = maskType
        self.cornerRadius = cornerRadius
    }
}

/// Advanced network image component with full ImageDownloader integration
///
/// Features:
/// - Full cache control (high/low priority)
/// - Progress tracking
/// - Disk storage support
/// - Multiple mask types (circle, ellipse, rounded)
/// - Crop support
///
/// Note: Due to ComponentKit's C++ requirements, this class bridges to Objective-C++
/// implementation. Use the factory methods to create instances.
@objc public class NetworkImageView: NSObject {

    // MARK: - Factory Methods

    /// Primary initializer with full configuration
    ///
    /// - Parameters:
    ///   - urlString: Image URL
    ///   - size: Component size
    ///   - options: Configuration options
    ///   - attributes: View attributes for UIImageView
    /// - Returns: CKComponent instance (bridged from Objective-C++)
    @objc public static func new(
        url urlString: String,
        size: CKComponentSize,
        options: NetworkImageViewOptions,
        attributes: CKViewComponentAttributeValueMap
    ) -> CKComponent {
        return NetworkImageViewBridge.createComponent(
            with: urlString,
            size: size,
            options: options,
            attributes: attributes
        )
    }

    /// Convenience: Basic image with placeholder
    @objc public static func new(
        url urlString: String,
        placeholder: UIImage?,
        size: CKComponentSize,
        attributes: CKViewComponentAttributeValueMap
    ) -> CKComponent {
        let options = NetworkImageViewOptions()
        options.placeholder = placeholder
        options.cachePriority = .low
        options.shouldSaveToStorage = false

        return new(url: urlString, size: size, options: options, attributes: attributes)
    }

    /// Convenience: Image with mask type
    @objc public static func new(
        url urlString: String,
        placeholder: UIImage?,
        size: CKComponentSize,
        maskType: ImageMaskType,
        radius cornerRadius: CGFloat,
        attributes: CKViewComponentAttributeValueMap
    ) -> CKComponent {
        let options = NetworkImageViewOptions()
        options.placeholder = placeholder
        options.maskType = maskType
        options.cornerRadius = cornerRadius
        options.cachePriority = .low
        options.shouldSaveToStorage = true

        return new(url: urlString, size: size, options: options, attributes: attributes)
    }

    /// Convenience: High priority cached image with progress
    @objc public static func new(
        url urlString: String,
        placeholder: UIImage?,
        size: CKComponentSize,
        cachePriority priority: ResourcePriority,
        onProgress progressBlock: ((CGFloat) -> Void)?,
        attributes: CKViewComponentAttributeValueMap
    ) -> CKComponent {
        let options = NetworkImageViewOptions()
        options.placeholder = placeholder
        options.cachePriority = priority
        options.shouldSaveToStorage = true
        options.onProgress = progressBlock

        return new(url: urlString, size: size, options: options, attributes: attributes)
    }
}
