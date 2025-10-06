//
//  StoragePathProvider.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

// MARK: - Storage Path Provider

/// Protocol for determining storage paths for resources
public protocol StoragePathProvider {
    /// Generate the relative file path for storing a resource
    /// - Parameters:
    ///   - url: The resource URL
    ///   - identifier: The unique identifier for this resource
    /// - Returns: Relative path within the storage directory (e.g., "images/abc123.png")
    func path(for url: URL, identifier: String) -> String

    /// Get the directory structure (subdirectories) for organizing storage
    /// - Parameter url: The resource URL
    /// - Returns: Array of subdirectory names (e.g., ["images", "2025"] for "images/2025/file.png")
    func directoryStructure(for url: URL) -> [String]
}
