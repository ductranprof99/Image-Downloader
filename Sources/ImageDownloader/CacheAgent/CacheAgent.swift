//
//  CacheAgent.swift
//  ImageDownloader
//
//  Two-tier memory cache with LRU eviction
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum CachePriority {
    case low    // Can be cleared by memory pressure, replaced when out of slots
    case high   // Only cleared by explicit clear/reset, saved to storage when evicted
}

public protocol CacheAgentDelegate: AnyObject {
    func cacheDidEvictImage(for url: URL, priority: CachePriority)
}

private class CacheEntry {
    var image: UIImage
    var url: URL
    var lastAccessDate: Date
    var priority: CachePriority

    init(image: UIImage, url: URL, priority: CachePriority) {
        self.image = image
        self.url = url
        self.priority = priority
        self.lastAccessDate = Date()
    }
}

public class CacheAgent {

    // MARK: - Properties

    public weak var delegate: CacheAgentDelegate?

    private var cacheData: [String: CacheEntry] = [:]
    private var highPriorityKeys: [String] = []
    private var lowPriorityKeys: [String] = []
    private let highPriorityLimit: Int
    private let lowPriorityLimit: Int
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.cacheagent.isolation")

    // MARK: - Initialization

    public init(highPriorityLimit: Int = 50, lowPriorityLimit: Int = 100) {
        self.highPriorityLimit = highPriorityLimit
        self.lowPriorityLimit = lowPriorityLimit
        setupMemoryWarningObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    public func image(for url: URL) -> UIImage? {
        isolationQueue.sync {
            let urlKey = url.absoluteString
            guard let entry = cacheData[urlKey] else { return nil }

            entry.lastAccessDate = Date()

            // Update LRU: move to end (most recently used)
            if entry.priority == .high {
                highPriorityKeys.removeAll { $0 == urlKey }
                highPriorityKeys.append(urlKey)
            } else {
                lowPriorityKeys.removeAll { $0 == urlKey }
                lowPriorityKeys.append(urlKey)
            }

            return entry.image
        }
    }

    public func setImage(_ image: UIImage, for url: URL, priority: CachePriority) {
        isolationQueue.sync {
            let urlKey = url.absoluteString

            // Check if already exists
            if let existingEntry = cacheData[urlKey] {
                // Update existing entry
                existingEntry.image = image
                existingEntry.lastAccessDate = Date()

                // Update priority if changed
                if existingEntry.priority != priority {
                    if existingEntry.priority == .high {
                        highPriorityKeys.removeAll { $0 == urlKey }
                    } else {
                        lowPriorityKeys.removeAll { $0 == urlKey }
                    }

                    existingEntry.priority = priority

                    if priority == .high {
                        highPriorityKeys.append(urlKey)
                    } else {
                        lowPriorityKeys.append(urlKey)
                    }
                } else {
                    // Just update LRU position
                    if priority == .high {
                        highPriorityKeys.removeAll { $0 == urlKey }
                        highPriorityKeys.append(urlKey)
                    } else {
                        lowPriorityKeys.removeAll { $0 == urlKey }
                        lowPriorityKeys.append(urlKey)
                    }
                }
            } else {
                // Create new entry
                let entry = CacheEntry(image: image, url: url, priority: priority)
                cacheData[urlKey] = entry

                if priority == .high {
                    highPriorityKeys.append(urlKey)
                    evictHighPriorityCacheIfNeeded()
                } else {
                    lowPriorityKeys.append(urlKey)
                    evictLowPriorityCacheIfNeeded()
                }
            }
        }
    }

    public func setImportantImage(_ image: UIImage, for url: URL) {
        setImage(image, for: url, priority: .high)
    }

    public func clearImportantCache(for url: URL) {
        isolationQueue.sync {
            let urlKey = url.absoluteString
            guard let entry = cacheData[urlKey], entry.priority == .high else { return }

            cacheData.removeValue(forKey: urlKey)
            highPriorityKeys.removeAll { $0 == urlKey }
        }
    }

    public func containsImage(for url: URL) -> Bool {
        isolationQueue.sync {
            cacheData[url.absoluteString] != nil
        }
    }

    public func clearLowPriorityCache() {
        isolationQueue.sync {
            for urlKey in lowPriorityKeys {
                cacheData.removeValue(forKey: urlKey)
            }
            lowPriorityKeys.removeAll()
        }
    }

    public func clearAllCache() {
        isolationQueue.sync {
            cacheData.removeAll()
            highPriorityKeys.removeAll()
            lowPriorityKeys.removeAll()
        }
    }

    public func hardReset() {
        clearAllCache()
    }

    public func highPriorityCacheCount() -> Int {
        isolationQueue.sync {
            highPriorityKeys.count
        }
    }

    public func lowPriorityCacheCount() -> Int {
        isolationQueue.sync {
            lowPriorityKeys.count
        }
    }

    // MARK: - Private Methods

    private func evictHighPriorityCacheIfNeeded() {
        // Must be called on isolationQueue
        while highPriorityKeys.count > highPriorityLimit {
            // Evict least recently used (first item)
            let urlKey = highPriorityKeys.first!
            let entry = cacheData[urlKey]

            if let entry = entry {
                // Notify delegate for saving to storage
                let url = entry.url
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.cacheDidEvictImage(for: url, priority: .high)
                }
            }

            cacheData.removeValue(forKey: urlKey)
            highPriorityKeys.removeFirst()
        }
    }

    private func evictLowPriorityCacheIfNeeded() {
        // Must be called on isolationQueue
        while lowPriorityKeys.count > lowPriorityLimit {
            // Evict least recently used (first item)
            let urlKey = lowPriorityKeys.first!
            cacheData.removeValue(forKey: urlKey)
            lowPriorityKeys.removeFirst()
            // No need to save to storage for low priority
        }
    }

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.clearLowPriorityCache()
        }
    }
}
