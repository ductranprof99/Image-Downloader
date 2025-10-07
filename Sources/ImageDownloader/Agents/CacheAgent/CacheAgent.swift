//
//  CacheAgent.swift
//  ImageDownloader
//
//  Two-tier memory cache with LRU eviction
//  Refactored to use Actor for thread-safe async/await
//

import Foundation
import UIKit

/// CacheAgent manages a two-tier LRU cache for images
internal actor CacheAgent {
    // MARK: - Properties
//    weak var delegate: CacheAgentDelegate?

    /// All cached entries indexed by URL string
    private var cacheData: [String: CacheEntry] = [:]

    /// High priority LRU queue (least recent first, most recent last)
    private var highPriorityKeys: [String] = []

    /// Low priority LRU queue (least recent first, most recent last)
    private var lowPriorityKeys: [String] = []

    private let highPriorityLimit: Int
    private let lowPriorityLimit: Int
    private let config: CacheConfig

    // MARK: - Initialization

    init(config: CacheConfig) {
        self.config = config
        self.highPriorityLimit = config.highPriorityLimit
        self.lowPriorityLimit = config.lowPriorityLimit
        setupMemoryWarningObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API (Actor-isolated async methods)

    /// Get image from cache and update LRU
    func image(for url: URL) -> UIImage? {
        let urlKey = url.absoluteString
        guard let entry = cacheData[urlKey] else { return nil }

        // Update access time
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

    /// Set image in cache with priority
    func setImage(_ image: UIImage, for url: URL, priority: CachePriority) async {
        let urlKey = url.absoluteString

        // Check if already exists
        if let existingEntry = cacheData[urlKey] {
            // Update existing entry
            existingEntry.image = image
            existingEntry.lastAccessDate = Date()

            // Update priority if changed
            if existingEntry.priority != priority {
                // Remove from old priority queue
                if existingEntry.priority == .high {
                    highPriorityKeys.removeAll { $0 == urlKey }
                } else {
                    lowPriorityKeys.removeAll { $0 == urlKey }
                }

                // Update priority
                existingEntry.priority = priority

                // Add to new priority queue
                if priority == .high {
                    highPriorityKeys.append(urlKey)
                } else {
                    lowPriorityKeys.append(urlKey)
                }
            } else {
                // Just update LRU position (move to end)
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
            let entry = CacheEntry(image: image,
                                   url: url,
                                   priority: priority)
            cacheData[urlKey] = entry

            if priority == .high {
                highPriorityKeys.append(urlKey)
                await evictHighPriorityCacheIfNeeded()
            } else {
                lowPriorityKeys.append(urlKey)
                evictLowPriorityCacheIfNeeded()
            }
        }
    }

    /// Set image as high priority (convenience method)
    nonisolated func setImportantImage(_ image: UIImage, for url: URL) {
        Task {
            await setImage(image, for: url, priority: .high)
        }
    }

    /// Clear specific high priority image
    func clearImportantCache(for url: URL) {
        let urlKey = url.absoluteString
        guard let entry = cacheData[urlKey], entry.priority == .high else { return }

        cacheData.removeValue(forKey: urlKey)
        highPriorityKeys.removeAll { $0 == urlKey }
    }

    /// Check if cache contains image for URL
    func containsImage(for url: URL) -> Bool {
        cacheData[url.absoluteString] != nil
    }

    /// Clear all low priority cache
    func clearLowPriorityCache() {
        for urlKey in lowPriorityKeys {
            cacheData.removeValue(forKey: urlKey)
        }
        lowPriorityKeys.removeAll()
    }

    /// Clear all cache (both high and low priority)
    func clearAllCache() {
        cacheData.removeAll()
        highPriorityKeys.removeAll()
        lowPriorityKeys.removeAll()
    }

    /// Hard reset (alias for clearAllCache)
    func hardReset() {
        clearAllCache()
    }

    /// Get high priority cache count
    func highPriorityCacheCount() -> Int {
        highPriorityKeys.count
    }

    /// Get low priority cache count
    func lowPriorityCacheCount() -> Int {
        lowPriorityKeys.count
    }

    // MARK: - Private Methods

    /// Evict least recently used high priority images if over limit
    /// Notifies delegate for potential storage saving
    private func evictHighPriorityCacheIfNeeded() async {
        while highPriorityKeys.count > highPriorityLimit {
            // Evict least recently used (first item)
            let urlKey = highPriorityKeys.first!
            let entry = cacheData[urlKey]

            if let entry = entry {
                // Notify delegate for saving to storage
                let url = entry.url

                // Call delegate on main thread if needed
//                if let delegate = delegate {
//                    Task { @MainActor in
//                        delegate.cacheDidEvictImage(for: url, priority: .high)
//                    }
//                }
            }

            cacheData.removeValue(forKey: urlKey)
            highPriorityKeys.removeFirst()
        }
    }

    /// Evict least recently used low priority images if over limit
    /// Low priority images are not saved to storage
    private func evictLowPriorityCacheIfNeeded() {
        while lowPriorityKeys.count > lowPriorityLimit {
            // Evict least recently used (first item)
            let urlKey = lowPriorityKeys.first!
            cacheData.removeValue(forKey: urlKey)
            lowPriorityKeys.removeFirst()
            // No need to save to storage for low priority
        }
    }

    /// Setup observer for memory warnings to clear cache based on configuration
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task {
                // More aggressive cache clearing on memory warning
                if self.config.clearAllOnMemoryWarning {
                    await self.clearAllCache()
                } else if self.config.clearLowPriorityOnMemoryWarning {
                    await self.clearLowPriorityCache()
                    // Also trim high priority cache to half
                    while await self.highPriorityKeys.count > (self.highPriorityLimit / 2) {
                        await self.evictHighPriorityCacheIfNeeded()
                    }
                }
            }
        }
    }
}
