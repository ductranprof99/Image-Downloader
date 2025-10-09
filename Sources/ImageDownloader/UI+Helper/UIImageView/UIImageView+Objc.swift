//
//  UIImageView+Objc.swift
//  ImageDownloader
//
//  Created by Duc Tran  on 7/10/25.
//

import UIKit

// MARK: - UIImageView Objective-C Extensions

extension UIImageView {

    /// Objective-C compatible method to set image from URL, immediately download
    @objc public func setImageObjC(
        with url: URL
    ) {
        setImageObjc(
            with: url,
            priority: .high
        )
    }

    /// Objective-C compatible method with priority download
    @objc public func setImageObjC(
        with url: URL,
        placeholder: UIImage?,
        priority: DownloadPriority,
        completion: ((UIImage?, NSError?) -> Void)? = nil
    ) {
        setImageObjc(
            with: url,
            placeholder: placeholder,
            priority: priority,
            onCompletion: { image, error, _, _ in
                completion?(image, error as NSError?)
            }
        )
    }
    
    @objc public func setImageObjC(
        with url: URL,
        config: IDConfiguration?,
        placeholderImage: UIImage?,
        errorImage: UIImage?,
        priority: DownloadPriority,
        progress: ((CGFloat, CGFloat, CGFloat) -> Void)?,
        completion: ((UIImage?, NSError?) -> Void)?
    ) {
        setImageObjc(
            with: url,
            placeholder: placeholderImage,
            errorImage: errorImage,
            config: config,
            priority: priority,
            onProgress: { progress, speed, bytes in
                
            },
            onCompletion: { image, error, _, _ in
                completion?(image, error as NSError?)
            }
        )
    }

    /// Objective-C compatible method to cancel loading
    @objc public func cancelDownloading(isSelf: Bool = true) {
        guard let url = currentLoadingURL else { return }
        if isSelf {
            downloadManager?.cancelAllRequests(for: url)
        } else {
            downloadManager?.cancelRequest(for: url, caller: self)
        }
        
    }
}

extension UIImageView {
    private static var currentURLKey: UInt8 = 1
    private static var managerKey: UInt8 = 2

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
    
    private var downloadManager: ImageDownloaderManager? {
        get {
            return objc_getAssociatedObject(self, &Self.managerKey) as? ImageDownloaderManager
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.managerKey,
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
    private func setImageObjc(
        with url: URL,
        placeholder: UIImage? = nil,
        errorImage: UIImage? = nil,
        config: IDConfiguration? = nil,
        manager: ImageDownloaderManager? = nil,
        priority: DownloadPriority = .low,
        transformation: ImageTransformation? = nil,
        onProgress: ((CGFloat, CGFloat, CGFloat) -> Void)? = nil,
        onCompletion: ((UIImage?, Error?, Bool, Bool) -> Void)? = nil
    ) {
        let newManager = config == nil ? ImageDownloaderManager.shared : ImageDownloaderManager.instance(for: config)
        downloadManager = manager ?? newManager
        // Store current URL
        currentLoadingURL = url

        // Show placeholder immediately
        if let placeholder = placeholder {
            self.image = placeholder
        }

        // Request image
        downloadManager?.requestImage(
            at: url,
            caller: self,
            downloadPriority: priority,
            progress: onProgress,
            completion: { [weak self] image, error, fromCache, fromStorage in
                guard let self = self else { return }

                // Apply transformation if provided
                let finalImage: UIImage?
                if let image = image, let transformation = transformation {
                    finalImage = transformation.transform(image)
                } else {
                    finalImage = image
                }

                // Update UI
                if let finalImage = finalImage {
                    self.image = finalImage
                } else if let errorImage = errorImage {
                    self.image = errorImage
                }

                // Call completion
                onCompletion?(finalImage, error, fromCache, fromStorage)
            }
        )
    }
}
