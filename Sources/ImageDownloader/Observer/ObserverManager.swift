//
//  ObserverManager.swift
//  ImageDownloader
//
//  Created by ductd on 6/10/25.
//

import Foundation

class ObserverManager {

    // MARK: - Properties

    private var observers = NSHashTable<AnyObject>.weakObjects()
    private let observerQueue = DispatchQueue(label: "com.imagedownloader.observer.queue")

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    func addObserver(_ observer: ImageDownloaderObserver) {
        observerQueue.sync {
            observers.add(observer as AnyObject)
        }
    }

    func removeObserver(_ observer: ImageDownloaderObserver) {
        observerQueue.sync {
            observers.remove(observer as AnyObject)
        }
    }

    func notifyImageDidLoad(url: URL, fromCache: Bool, fromStorage: Bool) {
        observerQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a local copy of observers to avoid mutation while iterating
            let currentObservers = self.observers.allObjects.compactMap { $0 as? ImageDownloaderObserver }
            
            // Remove any nil observers to keep the table clean
            self.observers.allObjects.forEach { observer in
                if observer as? ImageDownloaderObserver == nil {
                    self.observers.remove(observer)
                }
            }
            
            // Notify observers
            for observer in currentObservers {
                if observer.requiresMainThread {
                    DispatchQueue.main.async { [weak observer] in
                        observer?.imageDidLoad(for: url, fromCache: fromCache, fromStorage: fromStorage)
                    }
                } else {
                    observer.imageDidLoad(for: url, fromCache: fromCache, fromStorage: fromStorage)
                }
            }
        }
    }

    func notifyImageDidFail(url: URL, error: Error) {
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

    func notifyDownloadProgress(url: URL, progress: CGFloat) {
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

    func notifyWillStartDownloading(url: URL) {
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
