//
//  AsyncImageView.swift
//  ImageDownloaderUI - UIKit adapter for ImageDownloader
//
//  UIImageView subclass with built-in image loading
//

import UIKit
import ImageDownloader

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
open class AsyncImageView: UIImageView {

    // MARK: - Configuration Properties

    /// Placeholder image shown while loading or on error
    open var placeholderImage: UIImage?

    /// Current image URL being loaded
    private(set) public var imageURL: URL?

    /// Cache priority (default: .low)
    open var priority: ResourcePriority = .low

    /// Whether to save downloaded image to disk storage (default: true)
    open var shouldSaveToStorage: Bool = true

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
        priority = .low
        shouldSaveToStorage = true
        isLoading = false
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }

    deinit {
        cancelLoading()
    }

    // MARK: - Loading Methods

    /// Load image from URL with current configuration
    /// - Parameter url: Image URL to load
    open func loadImage(from url: URL) {
        loadImage(
            from: url,
            placeholder: placeholderImage,
            priority: priority,
            shouldSaveToStorage: shouldSaveToStorage
        )
    }

    /// Load image from URL with placeholder
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image to show while loading
    open func loadImage(from url: URL, placeholder: UIImage?) {
        loadImage(
            from: url,
            placeholder: placeholder,
            priority: priority,
            shouldSaveToStorage: shouldSaveToStorage
        )
    }

    /// Load image from URL with full configuration
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image to show while loading
    ///   - priority: Cache priority
    ///   - shouldSaveToStorage: Whether to save to disk storage
    open func loadImage(
        from url: URL,
        placeholder: UIImage?,
        priority: ResourcePriority,
        shouldSaveToStorage: Bool
    ) {
        // Cancel previous request if URL changed
        if let currentURL = imageURL, currentURL != url {
            cancelLoading()
        }

        imageURL = url
        isLoading = true

        // Show placeholder immediately
        if let placeholder = placeholder {
            self.image = placeholder
        }

        // Request image from ImageDownloaderManager
        ImageDownloaderManager.shared.requestImage(
            at: url,
            priority: priority,
            shouldSaveToStorage: shouldSaveToStorage,
            progress: { [weak self] progress in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.onProgress?(progress)
                }
            },
            completion: { [weak self] image, error, fromCache, fromStorage in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    // Only update if URL hasn't changed
                    if self.imageURL == url {
                        self.isLoading = false

                        if let image = image {
                            self.image = image
                        } else if error != nil, let placeholder = placeholder {
                            // Keep placeholder on error
                            self.image = placeholder
                        }

                        // Call user completion callback
                        self.onCompletion?(image, error, fromCache, fromStorage)
                    }
                }
            },
            caller: self
        )
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
