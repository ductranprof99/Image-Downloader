//
//  MD5IdentifierProvider.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//


import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CryptoKit

// MARK: - Default Identifier Providers

/// Default identifier provider using MD5 hash (backward compatible)
public class MD5IdentifierProvider: ResourceIdentifierProvider {
    public init() {}

    public func identifier(for url: URL) -> String {
        let urlString = url.absoluteString

        if #available(iOS 13.0, macOS 10.15, *) {
            let hash = Insecure.MD5.hash(data: Data(urlString.utf8))
            return hash.map { String(format: "%02x", $0) }.joined()
        } else {
            // Fallback for older OS versions
            return urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
        }
    }
}

/// SHA256 identifier provider (more secure, recommended for new projects)
public class SHA256IdentifierProvider: ResourceIdentifierProvider {
    public init() {}

    public func identifier(for url: URL) -> String {
        let urlString = url.absoluteString
        let hash = SHA256.hash(data: Data(urlString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
