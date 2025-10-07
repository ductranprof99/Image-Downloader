//
//  NetworkConfig.swift
//  ImageDownloader
//
//  Internal network configuration implementation
//

import Foundation

/// Internal network configuration with standard settings
struct NetworkConfig {
    var maxConcurrentDownloads: Int
    var timeout: TimeInterval
    var allowsCellularAccess: Bool
    var retryPolicy: RetryPolicy
    var customHeaders: [String: String]?
    var authenticationHandler: ((inout URLRequest) -> Void)?

    // Default initializer
    init(
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

// MARK: - Background Downloads Note
// URLSession handles background downloads natively via sessionSendsLaunchEvents
// No need for UIApplication.beginBackgroundTask() - that's only for 30-second tasks
