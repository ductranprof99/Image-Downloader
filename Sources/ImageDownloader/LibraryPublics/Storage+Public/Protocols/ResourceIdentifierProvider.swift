//
//  ResourceIdentifierProvider.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

// MARK: - Resource Identifier Provider

/// Protocol for generating unique identifiers for resources
@objc public protocol ResourceIdentifierProvider {
    /// Generate a unique identifier for the given URL
    /// - Parameter url: The resource URL
    /// - Returns: A unique identifier string (used for cache keys and file naming)
    func identifier(for url: URL) -> String
}
