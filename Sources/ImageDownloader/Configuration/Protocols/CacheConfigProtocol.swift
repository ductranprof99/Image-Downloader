//
//  CacheConfigProtocol.swift
//  ImageDownloader
//
//  Cache configuration protocol for injectable config system
//

import Foundation

/// Protocol defining cache-related configuration
public protocol CacheConfigProtocol {

    // MARK: - Cache Limits

    /// High priority cache limit (number of images, default: 50)
    var highPriorityLimit: Int { get }

    /// Low priority cache limit (number of images, default: 100)
    var lowPriorityLimit: Int { get }

    // MARK: - Cache Behavior

    /// Whether to clear low priority cache on memory warning (default: true)
    var clearLowPriorityOnMemoryWarning: Bool { get }

    /// Whether to clear all cache on memory warning (default: false)
    var clearAllOnMemoryWarning: Bool { get }
}

// MARK: - Default Implementation

extension CacheConfigProtocol {
    public var highPriorityLimit: Int { 50 }
    public var lowPriorityLimit: Int { 100 }
    public var clearLowPriorityOnMemoryWarning: Bool { true }
    public var clearAllOnMemoryWarning: Bool { false }
}
