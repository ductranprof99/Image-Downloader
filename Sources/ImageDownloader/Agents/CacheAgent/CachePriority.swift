//
//  CachePriority.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//


import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum CachePriority {
    case low    // Can be cleared by memory pressure, replaced when out of slots
    case high   // Only cleared by explicit clear/reset, saved to storage when evicted
}

public protocol CacheAgentDelegate: AnyObject {
    func cacheDidEvictImage(for url: URL, priority: CachePriority)
}
