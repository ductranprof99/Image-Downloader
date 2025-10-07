//
//  IDNetworkConfig.swift
//  ImageDownloader
//
//  Objective-C compatible network configuration
//

import Foundation

/// Objective-C compatible network configuration class
@objc public class IDNetworkConfig: NSObject {

    // MARK: - Connection Settings

    @objc public var maxConcurrentDownloads: Int
    @objc public var timeout: TimeInterval
    @objc public var allowsCellularAccess: Bool

    // MARK: - Retry Settings

    @objc public var retryPolicy: IDRetryPolicy

    // MARK: - Authentication & Headers

    @objc public var customHeaders: [String: String]?

    // Note: authenticationHandler cannot be bridged to Objective-C
    public var authenticationHandler: ((inout URLRequest) -> Void)?

    // MARK: - Initialization

    @objc public init(
        maxConcurrentDownloads: Int = 4,
        timeout: TimeInterval = 30,
        allowsCellularAccess: Bool = true,
        retryPolicy: IDRetryPolicy = IDRetryPolicy.defaultPolicy(),
        customHeaders: [String: String]? = nil
    ) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.timeout = timeout
        self.allowsCellularAccess = allowsCellularAccess
        self.retryPolicy = retryPolicy
        self.customHeaders = customHeaders
        self.authenticationHandler = nil
        super.init()
    }

    // MARK: - Presets

    @objc public static func defaultConfig() -> IDNetworkConfig {
        return IDNetworkConfig()
    }

    // MARK: - Conversion
    func toInternalConfig() -> NetworkConfig {
        return NetworkConfig(
            maxConcurrentDownloads: maxConcurrentDownloads,
            timeout: timeout,
            allowsCellularAccess: allowsCellularAccess,
            retryPolicy: retryPolicy.toSwift(),
            customHeaders: customHeaders,
            authenticationHandler: authenticationHandler
        )
    }
}
