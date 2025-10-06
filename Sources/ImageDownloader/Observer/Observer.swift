//
//  Observer.swift
//  ImageDownloader
//
//  Observer pattern for global image loading notifications
//

import Foundation

public protocol ImageDownloaderObserver: AnyObject {
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool)
    func imageDidFail(for url: URL, error: Error)
    func imageDownloadProgress(for url: URL, progress: CGFloat)
    func imageWillStartDownloading(for url: URL)
}

// Default implementations to make all methods optional
public extension ImageDownloaderObserver {
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool) {}
    func imageDidFail(for url: URL, error: Error) {}
    func imageDownloadProgress(for url: URL, progress: CGFloat) {}
    func imageWillStartDownloading(for url: URL) {}
}

public class ObserverManager {

    // MARK: - Properties

    private var observers = NSHashTable<AnyObject>.weakObjects()
    private let observerQueue = DispatchQueue(label: "com.imagedownloader.observer.queue")

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    public func addObserver(_ observer: ImageDownloaderObserver) {
        observerQueue.sync {
            observers.add(observer as AnyObject)
        }
    }

    public func removeObserver(_ observer: ImageDownloaderObserver) {
        observerQueue.sync {
            observers.remove(observer as AnyObject)
        }
    }

    public func notifyImageDidLoad(url: URL, fromCache: Bool, fromStorage: Bool) {
        observerQueue.async { [weak self] in
            guard let self = self else { return }
            for observer in self.observers.allObjects {
                if let observer = observer as? ImageDownloaderObserver {
                    DispatchQueue.main.async {
                        observer.imageDidLoad(for: url, fromCache: fromCache, fromStorage: fromStorage)
                    }
                }
            }
        }
    }

    public func notifyImageDidFail(url: URL, error: Error) {
        observerQueue.async { [weak self] in
            guard let self = self else { return }
            for observer in self.observers.allObjects {
                if let observer = observer as? ImageDownloaderObserver {
                    DispatchQueue.main.async {
                        observer.imageDidFail(for: url, error: error)
                    }
                }
            }
        }
    }

    public func notifyDownloadProgress(url: URL, progress: CGFloat) {
        observerQueue.async { [weak self] in
            guard let self = self else { return }
            for observer in self.observers.allObjects {
                if let observer = observer as? ImageDownloaderObserver {
                    DispatchQueue.main.async {
                        observer.imageDownloadProgress(for: url, progress: progress)
                    }
                }
            }
        }
    }

    public func notifyWillStartDownloading(url: URL) {
        observerQueue.async { [weak self] in
            guard let self = self else { return }
            for observer in self.observers.allObjects {
                if let observer = observer as? ImageDownloaderObserver {
                    DispatchQueue.main.async {
                        observer.imageWillStartDownloading(for: url)
                    }
                }
            }
        }
    }
}
