//
//  ImageResult.swift
//  ImageDownloader
//
//  Result types for image download operations
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Result of an image download operation (Swift-only)
public struct ImageResult {
    public let image: UIImage
    public let url: URL
    public let fromCache: Bool
    public let fromStorage: Bool

    public init(image: UIImage, url: URL, fromCache: Bool, fromStorage: Bool) {
        self.image = image
        self.url = url
        self.fromCache = fromCache
        self.fromStorage = fromStorage
    }
}

/// Objective-C compatible result wrapper
@objc public class IDImageResult: NSObject {
    @objc public let image: UIImage
    @objc public let url: URL
    @objc public let fromCache: Bool
    @objc public let fromStorage: Bool

    @objc public init(image: UIImage, url: URL, fromCache: Bool, fromStorage: Bool) {
        self.image = image
        self.url = url
        self.fromCache = fromCache
        self.fromStorage = fromStorage
        super.init()
    }

    internal convenience init(from result: ImageResult) {
        self.init(
            image: result.image,
            url: result.url,
            fromCache: result.fromCache,
            fromStorage: result.fromStorage
        )
    }
}

/// Errors that can occur during image downloading
public enum ImageDownloaderError: Error {
    case invalidURL
    case networkError(Error)
    case decodingFailed
    case cancelled
    case notFound
    case timeout
    case unknown(Error)

    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingFailed:
            return "Failed to decode image data"
        case .cancelled:
            return "Download was cancelled"
        case .notFound:
            return "Image not found"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

/// Objective-C compatible error codes
@objc public enum IDErrorCode: Int {
    case invalidURL = 1001
    case networkError = 1002
    case decodingFailed = 1003
    case cancelled = 1004
    case notFound = 1005
    case timeout = 1006
    case unknown = 1999
}

extension ImageDownloaderError {
    /// Convert to NSError for Objective-C compatibility
    public var nsError: NSError {
        let domain = "com.imagedownloader.error"
        let code: Int
        let userInfo: [String: Any]

        switch self {
        case .invalidURL:
            code = IDErrorCode.invalidURL.rawValue
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        case .networkError(let error):
            code = IDErrorCode.networkError.rawValue
            userInfo = [
                NSLocalizedDescriptionKey: localizedDescription,
                NSUnderlyingErrorKey: error as NSError
            ]
        case .decodingFailed:
            code = IDErrorCode.decodingFailed.rawValue
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        case .cancelled:
            code = IDErrorCode.cancelled.rawValue
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        case .notFound:
            code = IDErrorCode.notFound.rawValue
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        case .timeout:
            code = IDErrorCode.timeout.rawValue
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        case .unknown(let error):
            code = IDErrorCode.unknown.rawValue
            userInfo = [
                NSLocalizedDescriptionKey: localizedDescription,
                NSUnderlyingErrorKey: error as NSError
            ]
        }

        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
}
