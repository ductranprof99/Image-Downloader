//
//  CacheAgent.swift
//  ImageDownloader
//
//  Two-tier memory cache with LRU eviction
//  Refactored to use Actor for thread-safe async/await
//

import Foundation
import UIKit

enum CacheFetchResult {
    case hit(UIImage)
    case wait
    case miss
}

/// CacheAgent manages a two-tier LRU cache for images
internal actor CacheAgent {
    // MARK: - Properties
    /// All cached entries indexed by URL string
    /// But it also act like a barrier, since this agent is actor, every access must be thread safe, if cache data contain that key -> it mean
    private var cacheData: [String: CacheEntry] = [:]

    /// High priority LRU queue (least recent first, most recent last)
    private var lowLatencyCache: [String] = []
    private let lowLatencyLimit: Int
    
    /// Low priority LRU queue (least recent first, most recent last)
    private var highLatencyCache: [String] = []
    private let highLatencyLimit: Int
   
    private let config: CacheConfig
    
    // MARK: - Initialization
    init(config: CacheConfig) {
        self.config = config
        self.highLatencyLimit = config.highLatencyLimit
        self.lowLatencyLimit = config.lowLatencyLimit
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Actor isolated set/get image
    /// Get image from cache and update LRU
    func image(for url: URL) -> CacheFetchResult {
        let urlKey = url.absoluteString
        guard let entry = cacheData[urlKey] else {
            cacheData[urlKey] = .default
            return .miss
        }
        
        if cacheData[urlKey] == .default {
            return .wait
        }
        

        // Update access time
        // Update LRU: move to end (most recently used)
        if entry.usuallyUpdate {
            highLatencyCache.removeAll { $0 == urlKey }
            highLatencyCache.append(urlKey)
        } else {
            lowLatencyCache.removeAll { $0 == urlKey }
            lowLatencyCache.append(urlKey)
        }

        return .hit(entry.image)
    }

    /// Set image in cache with priority
    func setImage(_ image: UIImage, for url: URL,isHighLatency usuallyUpdate: Bool) async {
        let urlKey = url.absoluteString

        if cacheData[urlKey] == .default {
            let entry = CacheEntry(image: image,
                                   url: url,
                                   usuallyUpdate: usuallyUpdate)
            cacheData[urlKey] = entry

            if usuallyUpdate {
                highLatencyCache.append(urlKey)
            } else {
                lowLatencyCache.append(urlKey)
            }
            evictMemory(isHighLatency: usuallyUpdate)
        } else if let existingEntry = cacheData[urlKey] {
            // Check if already exists with data
            existingEntry.image = image

            // Update priority if changed
            if existingEntry.usuallyUpdate != usuallyUpdate {
                // Remove from old cache (reverse logic -> if change from not usually to usually, the cache need clean is low latency)
                if usuallyUpdate {
                    lowLatencyCache.removeAll { $0 == urlKey }
                } else {
                    highLatencyCache.removeAll { $0 == urlKey }
                }

                // Update priority
                existingEntry.usuallyUpdate = usuallyUpdate

                // Add to new unique set
                if usuallyUpdate {
                    highLatencyCache.append(urlKey)
                } else {
                    lowLatencyCache.append(urlKey)
                }
            } else {
                // Just update LRU position (move to end)
                if usuallyUpdate {
                    highLatencyCache.removeAll { $0 == urlKey }
                    highLatencyCache.append(urlKey)
                } else {
                    lowLatencyCache.removeAll { $0 == urlKey }
                    lowLatencyCache.append(urlKey)
                }
            }
        }
    }

    
    // MARK: - Cache function
    /// Clear specific high priority image
    func clearCache(url: URL) {
        let urlKey = url.absoluteString
        guard let entry = cacheData[urlKey] else { return }
        
        if entry.usuallyUpdate {
            cacheData.removeValue(forKey: urlKey)
            highLatencyCache.removeAll { $0 == urlKey }
        } else {
            cacheData.removeValue(forKey: urlKey)
            lowLatencyCache.removeAll { $0 == urlKey }
        }
        return
    }
    
    func clearCache(isHighLatency: Bool) {
        if isHighLatency {
            for key in highLatencyCache {
                cacheData.removeValue(forKey: key)
            }
            highLatencyCache.removeAll()
            
        } else {
            for key in lowLatencyCache {
                cacheData.removeValue(forKey: key)
            }
            lowLatencyCache.removeAll()
        }
        return
    }

    /// Clear all cache (both high and low priority)
    func clearAllCache() {
        cacheData.removeAll()
        lowLatencyCache.removeAll()
        highLatencyCache.removeAll()
    }
    
    /// Get high priority cache count
    func highPriorityCacheCount() -> Int {
        lowLatencyCache.count
    }

    /// Get low priority cache count
    func lowPriorityCacheCount() -> Int {
        highLatencyCache.count
    }

    // MARK: - Private Methods

    /// Evict least recently used low priority images if over limit
    /// Low priority images are not saved to storage
    private func evictMemory(isHighLatency: Bool) {
        if isHighLatency {
            while highLatencyCache.count > highLatencyLimit {
                // Evict least recently used (first item)
                let urlKey = highLatencyCache.first!
                cacheData.removeValue(forKey: urlKey)
                highLatencyCache.removeFirst()
                // No need to save to storage for low priority
            }
        } else {
            while lowLatencyCache.count > lowLatencyLimit {
                // Evict least recently used (first item)
                let urlKey = lowLatencyCache.first!
                cacheData.removeValue(forKey: urlKey)
                lowLatencyCache.removeFirst()
                // No need to save to storage for low priority
            }
        }
        
    }
}
