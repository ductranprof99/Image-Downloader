//
//  CustomStoragePathProvider.swift
//  StorageStructure
//
//  Created by ductd on 9/10/25.
//

import Foundation
import ImageDownloader

/// Custom domain-based path provider that organizes by host and path
class CustomDomainPathProvider: NSObject, StoragePathProvider {

    func path(for url: URL, identifier: String) -> String {
        let host = url.host ?? "unknown"

        // Get first path component if exists
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let firstPath = pathComponents.first ?? "images"

        // Note: Extension will be added by compression provider during save
        // We use png as default for path construction
        return "\(host)/\(firstPath)/\(identifier).png"
    }

    func directoryStructure(for url: URL) -> [String] {
        let host = url.host ?? "unknown"
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let firstPath = pathComponents.first ?? "images"

        return [host, firstPath]
    }
}

/// Custom date-based path provider with time component
class CustomDateTimePathProvider: NSObject, StoragePathProvider {
    private let dateFormatter: DateFormatter

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd/HH"
        super.init()
    }

    func path(for url: URL, identifier: String) -> String {
        let datePath = dateFormatter.string(from: Date())
        // Use png as default extension
        return "\(datePath)/\(identifier).png"
    }

    func directoryStructure(for url: URL) -> [String] {
        let dateString = dateFormatter.string(from: Date())
        return dateString.components(separatedBy: "/")
    }
}

/// Custom ID range-based path provider
/// Organizes images by their ID number in the URL
/// Example: picsum.photos/id/237/... -> images/low-ids/237.png (ID < 200)
///          picsum.photos/id/500/... -> images/high-ids/500.png (ID >= 400)
///          Otherwise -> images/mid-ids/299.png
class CustomIDRangePathProvider: NSObject, StoragePathProvider {

    func path(for url: URL, identifier: String) -> String {
        let folder = folderForURL(url)
        // Use png as default extension
        return "images/\(folder)/\(identifier).png"
    }

    func directoryStructure(for url: URL) -> [String] {
        let folder = folderForURL(url)
        return ["images", folder]
    }

    private func folderForURL(_ url: URL) -> String {
        // Extract ID from URL path components
        // Expected format: .../id/NUMBER/...
        let components = url.pathComponents

        // Find "id" component and get the next one
        if let idIndex = components.firstIndex(of: "id"),
           idIndex + 1 < components.count,
           let imageID = Int(components[idIndex + 1]) {

            if imageID < 350 {
                return "low-ids"
            } else if imageID >= 700 {
                return "high-ids"
            } else {
                return "mid-ids"
            }
        }

        // Fallback if no ID found
        return "unknown-ids"
    }
}

