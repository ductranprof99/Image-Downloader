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
        with url: URL,
        placeholder: UIImage?,
        completion: ((UIImage?, NSError?) -> Void)? = nil
    ) {
        setImage(
            with: url,
            config: nil,
            placeholder: placeholder,
            errorImage: nil,
            priority: .low,
            transformation: nil,
            onProgress: nil,
            onCompletion: { image, error, _, _ in
                completion?(image, error as NSError?)
            }
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
        placeholder: UIImage?,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)? = nil,
        completion: ((UIImage?, NSError?) -> Void)? = nil
    ) {
        setImage(
            with: url,
            config: nil,
            placeholder: placeholder,
            errorImage: nil,
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
