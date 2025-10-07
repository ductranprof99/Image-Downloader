//
//  ImageDownloaderError.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import Foundation

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
    
    var code: Int {
        switch self {
        case .invalidURL:
            1001
        case .networkError:
            1002
        case .decodingFailed:
            1003
        case .cancelled:
            1004
        case .notFound:
            1005
        case .timeout:
            1006
        case .unknown:
            1999
        }
    }

    /// Convert to NSError for Objective-C compatibility
    public var nsError: NSError {
        let domain = "com.imagedownloader.error"
        let code: Int = self.code
        let userInfo: [String: Any]
        switch self {
        case .invalidURL:
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        case .networkError(let error):
            userInfo = [
                NSLocalizedDescriptionKey: localizedDescription,
                NSUnderlyingErrorKey: error as NSError
            ]
        case .unknown(let error):
            userInfo = [
                NSLocalizedDescriptionKey: localizedDescription,
                NSUnderlyingErrorKey: error as NSError
            ]
        default:
            userInfo = [NSLocalizedDescriptionKey: localizedDescription]
        }

        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
}
