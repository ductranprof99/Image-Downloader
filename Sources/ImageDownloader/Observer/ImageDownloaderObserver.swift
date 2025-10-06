//
//  Observer.swift
//  ImageDownloader
//
//  Observer pattern for global image loading notifications
//

import Foundation

public protocol ImageDownloaderObserver: AnyObject {
    /// Indicates whether the observer requires main thread callbacks
    /// Default implementation returns false
    var requiresMainThread: Bool { get }
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool)
    func imageDidFail(for url: URL, error: Error)
    func imageDownloadProgress(for url: URL, progress: CGFloat)
    func imageWillStartDownloading(for url: URL)
}

public extension ImageDownloaderObserver {
    var requiresMainThread: Bool { false }
}

// Default implementations to make all methods optional
public extension ImageDownloaderObserver {
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool) {}
    func imageDidFail(for url: URL, error: Error) {}
    func imageDownloadProgress(for url: URL, progress: CGFloat) {}
    func imageWillStartDownloading(for url: URL) {}
}
