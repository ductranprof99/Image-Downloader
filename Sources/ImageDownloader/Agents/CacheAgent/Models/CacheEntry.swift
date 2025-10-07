//
//  CacheEntry.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//


import Foundation
import UIKit

/// Internal cache entry tracking image, URL, access time, and priority
class CacheEntry {
    var image: UIImage
    var url: URL
    var lastAccessDate: Date
    var priority: CachePriority

    init(image: UIImage, url: URL, priority: CachePriority) {
        self.image = image
        self.url = url
        self.priority = priority
        self.lastAccessDate = Date()
    }
}
