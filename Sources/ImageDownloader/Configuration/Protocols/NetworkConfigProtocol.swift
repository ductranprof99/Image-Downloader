//
//  NetworkConfigProtocol.swift
//  ImageDownloader
//
//  Network configuration protocol for injectable config system
//

import Foundation

/// Protocol defining network-related configuration
public protocol NetworkConfigProtocol {

    // MARK: - Connection Settings

    /// Maximum number of concurrent downloads (default: 4)
    var maxConcurrentDownloads: Int { get }

    /// Request timeout in seconds (default: 30)
    var timeout: TimeInterval { get }

    /// Whether to allow downloads over cellular network (default: true)
    var allowsCellularAccess: Bool { get }

    // MARK: - Retry Settings

    /// Retry policy for failed downloads
    var retryPolicy: RetryPolicy { get }

    // MARK: - Authentication & Headers

    /// Custom HTTP headers to include in all requests
    var customHeaders: [String: String]? { get }

    /// Authentication handler to modify requests before sending
    /// Note: This is a reference type closure, so it can't have a default in protocol
    var authenticationHandler: ((inout URLRequest) -> Void)? { get }
}

// MARK: - Default Implementation

extension NetworkConfigProtocol {
    public var maxConcurrentDownloads: Int { 4 }
    public var timeout: TimeInterval { 30 }
    public var allowsCellularAccess: Bool { true }
    public var retryPolicy: RetryPolicy { .default }
    public var customHeaders: [String: String]? { nil }
    public var authenticationHandler: ((inout URLRequest) -> Void)? { nil }
}
