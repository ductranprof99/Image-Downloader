//
//  DefaultCacheConfig.swift
//  ImageDownloader
//
//  Default cache configuration implementation
//

import Foundation

/// Default cache configuration with standard settings
public struct DefaultCacheConfig: CacheConfigProtocol {
    public var highPriorityLimit: Int
    public var lowPriorityLimit: Int
    public var clearLowPriorityOnMemoryWarning: Bool
    public var clearAllOnMemoryWarning: Bool

    public init(
        highPriorityLimit: Int = 50,
        lowPriorityLimit: Int = 100,
        clearLowPriorityOnMemoryWarning: Bool = true,
        clearAllOnMemoryWarning: Bool = false
    ) {
        self.highPriorityLimit = highPriorityLimit
        self.lowPriorityLimit = lowPriorityLimit
        self.clearLowPriorityOnMemoryWarning = clearLowPriorityOnMemoryWarning
        self.clearAllOnMemoryWarning = clearAllOnMemoryWarning
    }
}
