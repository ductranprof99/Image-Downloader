//
//  IDDomainHierarchicalPathProvider.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import Foundation


// MARK: - Default Storage Path Providers

/// Default flat storage provider (all files in single directory)
public class FlatHierarchicalPathProvider: StoragePathProvider {
    public init() {}

    public func path(for url: URL, identifier: String) -> String {
        let lastComponent = url.lastPathComponent
        if !lastComponent.isEmpty {
            // Sanitize filename
            let invalidChars = CharacterSet.alphanumerics.inverted
            let sanitized = lastComponent.components(separatedBy: invalidChars).joined(separator: "_")
            let limitedSanitized = String(sanitized.prefix(50))
            return "\(identifier)_\(limitedSanitized)"
        }

        // Fallback: just identifier with extension
        let extension_ = !url.pathExtension.isEmpty ? url.pathExtension : "png"
        return "\(identifier).\(extension_)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        return []  // No subdirectories
    }
}

/// Hierarchical storage by domain (e.g., "example.com/abc123.png")
public class DomainHierarchicalPathProvider: StoragePathProvider {
    public init() {}

    public func path(for url: URL, identifier: String) -> String {
        let domain = url.host ?? "unknown"
        let ext = !url.pathExtension.isEmpty ? url.pathExtension : "png"
        return "\(domain)/\(identifier).\(ext)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        return [url.host ?? "unknown"]
    }
}

/// Hierarchical storage by date (e.g., "2025/10/06/abc123.png")
public class DateHierarchicalPathProvider: StoragePathProvider {
    private let dateFormatter: DateFormatter

    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
    }

    public func path(for url: URL, identifier: String) -> String {
        let datePrefix = dateFormatter.string(from: Date())
        let ext = !url.pathExtension.isEmpty ? url.pathExtension : "png"
        return "\(datePrefix)/\(identifier).\(ext)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        let dateString = dateFormatter.string(from: Date())
        return dateString.components(separatedBy: "/")
    }
}
