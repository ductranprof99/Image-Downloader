//
//  DefaultNetworkConfig.swift
//  ImageDownloader
//
//  Default network configuration implementation
//

import Foundation

/// Default network configuration with standard settings
public struct DefaultNetworkConfig: NetworkConfigProtocol {
    public var maxConcurrentDownloads: Int
    public var timeout: TimeInterval
    public var allowsCellularAccess: Bool
    public var retryPolicy: RetryPolicy
    public var customHeaders: [String: String]?
    public var authenticationHandler: ((inout URLRequest) -> Void)?

    public init(
        maxConcurrentDownloads: Int = 4,
        timeout: TimeInterval = 30,
        allowsCellularAccess: Bool = true,
        retryPolicy: RetryPolicy = .default,
        customHeaders: [String: String]? = nil,
        authenticationHandler: ((inout URLRequest) -> Void)? = nil
    ) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.timeout = timeout
        self.allowsCellularAccess = allowsCellularAccess
        self.retryPolicy = retryPolicy
        self.customHeaders = customHeaders
        self.authenticationHandler = authenticationHandler
    }
}
