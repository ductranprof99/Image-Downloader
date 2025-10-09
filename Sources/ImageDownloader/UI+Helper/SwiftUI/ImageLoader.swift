//
//  ImageLoader.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//

import SwiftUI


// MARK: - Better SwiftUI Implementation with Observable Progress

/// Observable object for tracking image loading progress
@available(iOS 13.0, macOS 10.15, *)
public class ImageLoader: ObservableObject {

    @Published public var image: UIImage?
    @Published public var isLoading = false
    @Published public var progress: CGFloat = 0.0
    @Published public var error: Error?

    private var url: URL?
    private var config: IDConfiguration?

    public init() {}

    @MainActor
    public func load(
        from url: URL,
        config: IDConfiguration? = nil,
        priority: DownloadPriority = .low
    ) {
        self.url = url
        self.config = config
        self.isLoading = true
        self.progress = 0.0
        self.error = nil

        // Use completion-based API for progress tracking
        let manager = ImageDownloaderManager.instance(for: config)
        
    }

    public func cancel() {
        guard let url = url else { return }
        let manager = ImageDownloaderManager.instance(for: config)
        manager.cancelRequest(for: url, caller: self)
        isLoading = false
    }
    
    public func forceAllURLRequest() {
        guard let url = url else { return }
        let manager = ImageDownloaderManager.instance(for: config)
        manager.cancelAllRequests(for: url)
        isLoading = false
    }
}
