//
//  ResourceModel.swift
//  ImageDownloader
//
//  Model representing a downloadable image resource
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

import CryptoKit

public enum ResourceState {
    case unknown
    case downloading
    case available
    case failed
}

@objc public enum ResourcePriority: Int {
    case low
    case high
}

internal class ResourceModel {

    // MARK: - Properties

    public let url: URL
    public let identifier: String
    public var state: ResourceState
    public var priority: ResourcePriority
    public var image: UIImage?
    public var error: Error?
    public var progress: CGFloat
    public private(set) var lastAccessDate: Date
    public var shouldSaveToStorage: Bool

    // MARK: - Initialization

    public init(url: URL, priority: ResourcePriority, identifierProvider: ResourceIdentifierProvider? = nil) {
        self.url = url
        // Use provided identifier provider or default to MD5
        let provider = identifierProvider ?? MD5IdentifierProvider()
        self.identifier = provider.identifier(for: url)
        self.priority = priority
        self.state = .unknown
        self.progress = 0.0
        self.shouldSaveToStorage = true
        self.lastAccessDate = Date()
    }

    // MARK: - Public Methods

    public func updateLastAccessDate() {
        lastAccessDate = Date()
    }
}
