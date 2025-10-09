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
    @objc public var highLatencyLimit: Int
    @objc public var lowLatencyLimit: Int

    // MARK: - Cache Behavior
    @objc public var clearLowPriorityOnMemoryWarning: Bool
    @objc public var clearAllOnMemoryWarning: Bool

    // MARK: - Initialization

    @objc public init(
        highLatencyLimit: Int = 50,
        lowLatencyLimit: Int = 100,
        clearLowPriorityOnMemoryWarning: Bool = true,
        clearAllOnMemoryWarning: Bool = false
    ) {
        self.highLatencyLimit = highLatencyLimit
        self.lowLatencyLimit = lowLatencyLimit
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
            highLatencyLimit: highLatencyLimit,
            lowLatencyLimit: lowLatencyLimit,
            clearLowPriorityOnMemoryWarning: clearLowPriorityOnMemoryWarning,
            clearAllOnMemoryWarning: clearAllOnMemoryWarning
        )
    }
}
