//
//  ResourceModel.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

internal class ResourceModel {
    // MARK: - Properties

    let url: URL
    let identifier: String
    var state: ResourceState
    var image: UIImage?
    var error: Error?
    var progress: CGFloat
    var shouldSaveToStorage: Bool

    // MARK: - Initialization

    public init(url: URL, identifierProvider: ResourceIdentifierProvider? = nil) {
        self.url = url
        // Use provided identifier provider or default to MD5
        let provider = identifierProvider ?? MD5IdentifierProvider()
        self.identifier = provider.identifier(for: url)
        self.state = .unknown
        self.progress = 0.0
        self.shouldSaveToStorage = true
    }
}
