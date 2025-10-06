//
//  ObserverManager.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

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
                    if observer.requiresMainThread {
                        DispatchQueue.main.async {
                            observer.imageDidLoad(for: url, fromCache: fromCache, fromStorage: fromStorage)
                        }
                    } else {
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
                    if observer.requiresMainThread {
                        DispatchQueue.main.async {
                            observer.imageDidFail(for: url, error: error)
                        }
                    } else {
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
                    if observer.requiresMainThread {
                        DispatchQueue.main.async {
                            observer.imageDownloadProgress(for: url, progress: progress)
                        }
                    } else {
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
                    if observer.requiresMainThread {
                        DispatchQueue.main.async {
                            observer.imageWillStartDownloading(for: url)
                        }
                    } else {
                        observer.imageWillStartDownloading(for: url)
                    }
                }
            }
        }
    }
}
