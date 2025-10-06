//
//  UIImageView+ImageDownloader.swift
//  ImageDownloaderUI
//
//  Convenience extension for adding image loading to any UIImageView
//

#if canImport(UIKit)
import UIKit
#endif

import ImageDownloader
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

    private static var currentURLKey: UInt8 = 0

    // MARK: - Private Properties

    private var currentLoadingURL: URL? {
        get {
            return objc_getAssociatedObject(self, &Self.currentURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.currentURLKey,
                newValue,
                .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }

    // MARK: - Public API (New Injectable Config API)

    /// Load image from URL with injectable configuration
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - config: Custom configuration (nil = use default)
    ///   - placeholder: Placeholder image shown while loading or on error
    ///   - priority: Download priority (default: .low)
    ///   - onProgress: Progress callback (0.0 to 1.0)
    ///   - onCompletion: Completion callback with image result
    func setImage(
        with url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        placeholder: UIImage? = nil,
        priority: ResourcePriority = .low,
        onProgress: ((CGFloat) -> Void)? = nil,
        onCompletion: ((UIImage?, Error?, Bool, Bool) -> Void)? = nil
    ) {
        // Cancel previous request if URL changed
        if let currentURL = currentLoadingURL, currentURL != url {
            cancelImageLoading()
        }

        // Store current URL
        currentLoadingURL = url

        // Show placeholder immediately
        if let placeholder = placeholder {
            self.image = placeholder
        }

        // Get manager instance for this config
        let manager = ImageDownloaderManager.instance(for: config)

        // Request image
        manager.requestImage(
            at: url,
            priority: priority,
            shouldSaveToStorage: config?.storageConfig.shouldSaveToStorage ?? true,
            progress: { [weak self] progress in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    onProgress?(progress)
                }
            },
            completion: { [weak self] image, error, fromCache, fromStorage in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    // Only update if URL hasn't changed
                    if self.currentLoadingURL == url {
                        if let image = image {
                            self.image = image
                        } else if error != nil, let placeholder = placeholder {
                            // Keep placeholder on error
                            self.image = placeholder
                        }

                        // Call user completion callback
                        onCompletion?(image, error, fromCache, fromStorage)
                    }
                }
            },
            caller: self
        )
    }

    // MARK: - Public API (Legacy - Backward Compatible)

    /// Load image from URL with default settings
    /// - Parameter url: Image URL to load
    func setImage(with url: URL) {
        setImage(
            with: url,
            config: nil,
            placeholder: nil,
            priority: .low,
            onProgress: nil,
            onCompletion: nil
        )
    }

    /// Load image from URL with placeholder
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image shown while loading or on error
    func setImage(with url: URL, placeholder: UIImage?) {
        setImage(
            with: url,
            config: nil,
            placeholder: placeholder,
            priority: .low,
            onProgress: nil,
            onCompletion: nil
        )
    }

    /// Load image from URL with priority control
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image shown while loading or on error
    ///   - priority: Cache priority (.high or .low)
    func setImage(with url: URL, placeholder: UIImage?, priority: ResourcePriority) {
        setImage(
            with: url,
            config: nil,
            placeholder: placeholder,
            priority: priority,
            onProgress: nil,
            onCompletion: nil
        )
    }

    /// Load image from URL with progress tracking
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image shown while loading or on error
    ///   - priority: Cache priority
    ///   - onProgress: Progress callback (0.0 to 1.0)
    func setImage(
        with url: URL,
        placeholder: UIImage?,
        priority: ResourcePriority,
        onProgress: ((CGFloat) -> Void)?
    ) {
        setImage(
            with: url,
            config: nil,
            placeholder: placeholder,
            priority: priority,
            onProgress: onProgress,
            onCompletion: nil
        )
    }

    /// Load image from URL with full configuration and completion
    /// - Parameters:
    ///   - url: Image URL to load
    ///   - placeholder: Placeholder image shown while loading or on error
    ///   - priority: Cache priority
    ///   - shouldSaveToStorage: Whether to save to disk storage
    ///   - onProgress: Progress callback (0.0 to 1.0)
    ///   - onCompletion: Completion callback with image result
    func setImage(
        with url: URL,
        placeholder: UIImage?,
        priority: ResourcePriority,
        shouldSaveToStorage: Bool,
        onProgress: ((CGFloat) -> Void)?,
        onCompletion: ((UIImage?, Error?, Bool, Bool) -> Void)?
    ) {
        // Create temporary config with shouldSaveToStorage setting
        var storageConfig = DefaultStorageConfig()
        storageConfig.shouldSaveToStorage = shouldSaveToStorage

        let config = DefaultConfig(storageConfig: storageConfig)

        setImage(
            with: url,
            config: config,
            placeholder: placeholder,
            priority: priority,
            onProgress: onProgress,
            onCompletion: onCompletion
        )
    }

    /// Cancel current image loading for this UIImageView
    func cancelImageLoading() {
        if let currentURL = currentLoadingURL {
            ImageDownloaderManager.shared.cancelRequest(for: currentURL, caller: self)
            currentLoadingURL = nil
        }
    }
}
