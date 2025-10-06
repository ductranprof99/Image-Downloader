//
//  AnyResourceIdentifierProvider.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

// MARK: - Type-Erased Wrappers for Objective-C Compatibility
/// Type-erased wrapper for ResourceIdentifierProvider (Objective-C compatible)
@objc public class AnyResourceIdentifierProvider: NSObject {
    private let _identifier: (URL) -> String

    public init<T: ResourceIdentifierProvider>(_ provider: T) {
        self._identifier = provider.identifier
        super.init()
    }

    @objc public func identifier(for url: URL) -> String {
        return _identifier(url)
    }
}
