//
//  IDFlatStoragePathProvider.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import Foundation

// MARK: - Objective-C Compatible Providers
/// Objective-C compatible flat storage path provider
final class IDFlatStoragePathProvider: NSObject {
    private let provider = FlatHierarchicalPathProvider()

    override init() {
        super.init()
    }

    func path(for url: URL, identifier: String) -> String {
        return provider.path(for: url, identifier: identifier)
    }

    func directoryStructure(for url: URL) -> [String] {
        return provider.directoryStructure(for: url)
    }
}

