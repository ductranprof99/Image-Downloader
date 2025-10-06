//
//  AnyStoragePathProvider.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

/// Type-erased wrapper for StoragePathProvider (Objective-C compatible)
@objc public class AnyStoragePathProvider: NSObject {
    private let _path: (URL, String) -> String
    private let _directoryStructure: (URL) -> [String]

    public init<T: StoragePathProvider>(_ provider: T) {
        self._path = provider.path
        self._directoryStructure = provider.directoryStructure
        super.init()
    }

    @objc public func path(for url: URL, identifier: String) -> String {
        return _path(url, identifier)
    }

    @objc public func directoryStructure(for url: URL) -> [String] {
        return _directoryStructure(url)
    }
}
