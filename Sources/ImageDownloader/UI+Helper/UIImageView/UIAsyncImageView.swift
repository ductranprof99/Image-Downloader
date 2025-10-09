//
//  UIAsyncImageView.swift
//  ImageDownloaderUI - UIKit adapter for ImageDownloader
//
//  UIImageView subclass with built-in image loading
//

import UIKit

/// UIImageView subclass with built-in image loading support
///
/// Features:
/// - Automatic image loading from URL
/// - Placeholder support
/// - Progress tracking
/// - Cache priority control
/// - Disk storage configuration
/// - Automatic request cancellation on reuse/dealloc
///
/// Example usage:
/// ```swift
/// let imageView = AsyncImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
/// imageView.placeholderImage = UIImage(named: "placeholder")
/// imageView.priority = .high
/// imageView.loadImage(from: URL(string: "https://example.com/image.jpg")!)
/// ```
open class UIAsyncImageView: UIImageView {

    // MARK: - Configuration Properties

    /// Placeholder image shown while loading
    open var placeholderImage: UIImage?

    /// Error image shown when loading fails (if nil, keeps placeholder on error)
    open var errorImage: UIImage?

    /// Current image URL being loaded
    private(set) public var imageURL: URL?

    /// Cache priority (default: .low)
    open var config: IDConfiguration = .default

    /// Whether image is currently loading
    private(set) public var isLoading: Bool = false

    // MARK: - Callbacks

    /// Progress callback - reports download progress (0.0 to 1.0)
    open var onProgress: ((CGFloat) -> Void)?

    /// Completion callback - called when image loads or fails
    open var onCompletion: ((UIImage?, Error?, Bool, Bool) -> Void)?

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }

    deinit {
        cancelLoading()
    }

    // MARK: - Loading Methods
    /// Load image from URL with placeholder and error image
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image to show while loading
    ///   - errorImage: Image to show on error
    open func loadImage(from url: URL, placeholder: UIImage? = nil, errorImage: UIImage? = nil) {
        // TODO
    }

    /// Cancel current image loading request
    open func cancelLoading() {
        if let currentURL = imageURL {
            ImageDownloaderManager.shared.cancelRequest(for: currentURL, caller: self)
            imageURL = nil
            isLoading = false
        }
    }
}
