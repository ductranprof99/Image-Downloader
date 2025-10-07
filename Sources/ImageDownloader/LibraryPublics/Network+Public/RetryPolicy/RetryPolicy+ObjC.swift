//
//  IDRetryPolicy.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import Foundation

// MARK: - Objective-C Compatibility

/// Objective-C compatible retry policy class
@objc public class IDRetryPolicy: NSObject {

    @objc public let maxRetries: Int
    @objc public let baseDelay: TimeInterval
    @objc public let backoffMultiplier: Double
    @objc public let maxDelay: TimeInterval

    @objc public init(
        maxRetries: Int,
        baseDelay: TimeInterval,
        backoffMultiplier: Double,
        maxDelay: TimeInterval
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.backoffMultiplier = backoffMultiplier
        self.maxDelay = maxDelay
        super.init()
    }

    /// Convenience initializer from Swift RetryPolicy
    internal convenience init(from policy: RetryPolicy) {
        self.init(
            maxRetries: policy.maxRetries,
            baseDelay: policy.baseDelay,
            backoffMultiplier: policy.backoffMultiplier,
            maxDelay: policy.maxDelay
        )
    }

    @objc public static func defaultPolicy() -> IDRetryPolicy {
        return IDRetryPolicy(maxRetries: 3, baseDelay: 1.0, backoffMultiplier: 2.0, maxDelay: 30.0)
    }

    @objc public static func aggressivePolicy() -> IDRetryPolicy {
        return IDRetryPolicy(maxRetries: 5, baseDelay: 0.5, backoffMultiplier: 1.5, maxDelay: 15.0)
    }

    @objc public static func conservativePolicy() -> IDRetryPolicy {
        return IDRetryPolicy(maxRetries: 2, baseDelay: 2.0, backoffMultiplier: 3.0, maxDelay: 60.0)
    }

    @objc public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        let calculatedDelay = baseDelay * pow(backoffMultiplier, Double(attempt - 1))
        return min(calculatedDelay, maxDelay)
    }

    internal func toSwift() -> RetryPolicy {
        return RetryPolicy(
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            backoffMultiplier: backoffMultiplier,
            maxDelay: maxDelay
        )
    }
}
