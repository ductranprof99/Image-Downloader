//
//  CacheEntry.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//


import Foundation
import UIKit

/// Internal cache entry tracking image, URL, access time, and priority
class CacheEntry: Equatable {
    var isDefault: Int
    var image: UIImage
    var url: URL?
    
    /// Every cache can be replace, but put on high process cache make the update is lesser than normal
    var usuallyUpdate: Bool

    init(
        isDefault: Int = 0,
        image: UIImage,
        url: URL?,
        usuallyUpdate: Bool = false
    ) {
        self.isDefault = isDefault
        self.image = image
        self.url = url
        self.usuallyUpdate = usuallyUpdate
    }
    
    static func ==(lhs: CacheEntry, rhs: CacheEntry) -> Bool {
        return lhs.isDefault == rhs.isDefault && lhs.isDefault == 1
    }
    
    static let `default`: CacheEntry = .init(isDefault: 1, image: UIImage(), url: nil)
}
