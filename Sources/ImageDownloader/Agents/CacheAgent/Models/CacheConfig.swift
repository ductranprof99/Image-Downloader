//
//  CacheConfig.swift
//  ImageDownloader
//
//  Internal cache configuration implementation
//

import Foundation

/// Internal cache configuration with standard settings
struct CacheConfig {
    var highPriorityLimit: Int
    var lowPriorityLimit: Int
    var clearLowPriorityOnMemoryWarning: Bool
    var clearAllOnMemoryWarning: Bool

    // Default initializer
    init(
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
