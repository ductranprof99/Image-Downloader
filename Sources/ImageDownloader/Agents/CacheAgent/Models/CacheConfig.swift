//
//  CacheConfig.swift
//  ImageDownloader
//
//  Internal cache configuration implementation
//

import Foundation

/// Internal cache configuration with standard settings
struct CacheConfig {
    var highLatencyLimit: Int
    var lowLatencyLimit: Int
    var clearLowPriorityOnMemoryWarning: Bool
    var clearAllOnMemoryWarning: Bool

    // Default initializer
    init(
        highLatencyLimit: Int = 50,
        lowLatencyLimit: Int = 100,
        clearLowPriorityOnMemoryWarning: Bool = true,
        clearAllOnMemoryWarning: Bool = false
    ) {
        self.highLatencyLimit = highLatencyLimit
        self.lowLatencyLimit = lowLatencyLimit
        self.clearLowPriorityOnMemoryWarning = clearLowPriorityOnMemoryWarning
        self.clearAllOnMemoryWarning = clearAllOnMemoryWarning
    }
}
