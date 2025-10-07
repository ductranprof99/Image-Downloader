//
//  IDCacheConfig.swift
//  ImageDownloader
//
//  Objective-C compatible cache configuration
//

import Foundation

/// Objective-C compatible cache configuration class
@objc public class IDCacheConfig: NSObject {

    // MARK: - Cache Limits

    @objc public var highPriorityLimit: Int
    @objc public var lowPriorityLimit: Int

    // MARK: - Cache Behavior

    @objc public var clearLowPriorityOnMemoryWarning: Bool
    @objc public var clearAllOnMemoryWarning: Bool

    // MARK: - Initialization

    @objc public init(
        highPriorityLimit: Int = 50,
        lowPriorityLimit: Int = 100,
        clearLowPriorityOnMemoryWarning: Bool = true,
        clearAllOnMemoryWarning: Bool = false
    ) {
        self.highPriorityLimit = highPriorityLimit
        self.lowPriorityLimit = lowPriorityLimit
        self.clearLowPriorityOnMemoryWarning = clearLowPriorityOnMemoryWarning
        self.clearAllOnMemoryWarning = clearAllOnMemoryWarning
        super.init()
    }

    // MARK: - Presets

    @objc public static func defaultConfig() -> IDCacheConfig {
        return IDCacheConfig()
    }

    // MARK: - Conversion

    func toInternalConfig() -> CacheConfig {
        return CacheConfig(
            highPriorityLimit: highPriorityLimit,
            lowPriorityLimit: lowPriorityLimit,
            clearLowPriorityOnMemoryWarning: clearLowPriorityOnMemoryWarning,
            clearAllOnMemoryWarning: clearAllOnMemoryWarning
        )
    }
}
