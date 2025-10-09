//
//  UIImageView+Objc.swift
//  ImageDownloader
//
//  Created by Duc Tran  on 7/10/25.
//

import UIKit

// MARK: - UIImageView Objective-C Extensions

extension UIImageView {

    /// Objective-C compatible method to set image from URL
    @objc public func setImageObjC(
        with url: URL
    ) {
        setImage(
            with: url,
            config: nil,
            placeholder: nil,
            errorImage: nil,
            priority: .low,
            transformation: nil,
            onProgress: nil,
            onCompletion: nil
        )
    }

    /// Objective-C compatible method with priority
    @objc public func setImageObjC(
        with url: URL,
        placeholder: UIImage?,
        priority: ResourcePriority,
        completion: ((UIImage?, NSError?) -> Void)? = nil
    ) {
        setImage(
            with: url,
            config: nil,
            placeholder: placeholder,
            errorImage: nil,
            priority: priority,
            transformation: nil,
            onProgress: nil,
            onCompletion: { image, error, _, _ in
                completion?(image, error as NSError?)
            }
        )
    }
    
    @objc public func setImageObjC(
        with url: URL,
        config: IDConfiguration? = nil,
        placeholderImage: UIImage? = nil,
        errorImage: UIImage? = nil,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)? = nil,
        completion: ((UIImage?, NSError?) -> Void)? = nil
    ) {
        setImage(
            with: url,
            config: config,
            placeholder: placeholderImage,
            errorImage: errorImage,
            priority: priority,
            transformation: nil,
            onProgress: {
                progress?($0)
            },
            onCompletion: { image, error, _, _ in
                completion?(image, error as NSError?)
            }
        )
    }

    /// Objective-C compatible method to cancel loading
    @objc public func cancelImageLoadingObjC() {
        cancelImageLoading()
    }
}

extension UIImageView {
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
    ///   - placeholder: Placeholder image shown while loading
    ///   - errorImage: Image shown on error (if nil, keeps placeholder on error)
    ///   - priority: Download priority (default: .low)
    ///   - transformation: Optional image transformation to apply
    ///   - onProgress: Progress callback (0.0 to 1.0)
    ///   - onCompletion: Completion callback with image result
    func setImage(
        with url: URL,
        config: IDConfiguration? = nil,
        priority: ResourcePriority = .low,
        transformation: ImageTransformation? = nil,
        onProgress: ((CGFloat) -> Void)? = nil,
        onCompletion: ((UIImage?, Error?, Bool, Bool) -> Void)? = nil
    ) {
        let manager = config == nil ? ImageDownloaderManager.shared : ImageDownloaderManager.instance(for: config)
        // Cancel previous request if URL changed
        if let currentURL = currentLoadingURL, currentURL != url {
            cancelImageLoading(manager: manager)
        }

        // Store current URL
        currentLoadingURL = url

        // Show placeholder immediately
        if let placeholder = placeholder {
            self.image = placeholder
        }

        // Get manager instance for this config
       

        // Request image
        manager.requestImage(
            at: url,
            priority: priority,
            shouldSaveToStorage: config?.storage.shouldSaveToStorage ?? true,
            progress: { [weak self] progress in
                guard self != nil else { return }
                DispatchQueue.main.async {
                    onProgress?(progress)
                }
            },
            completion: { [weak self] image, error, fromCache, fromStorage in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    // Only update if URL hasn't changed
                    if self.currentLoadingURL == url {
                        if var image = image {
                            // Apply transformation if provided
                            if let transformation = transformation,
                               let transformedImage = transformation.transform(image) {
                                image = transformedImage
                            }
                            self.image = image
                        } else if error != nil {
                            // Show error image if provided, otherwise keep placeholder
                            if let errorImage = errorImage {
                                self.image = errorImage
                            } else if let placeholder = placeholder {
                                self.image = placeholder
                            }
                        }

                        // Call user completion callback
                        onCompletion?(image, error, fromCache, fromStorage)
                    }
                }
            }
        )
    }

    /// Cancel current image loading for this UIImageView
    func cancelImageLoading(manager: ImageDownloaderManager) {
        manager.cancelRequest(for: currentURL, caller: self)
    }
}
