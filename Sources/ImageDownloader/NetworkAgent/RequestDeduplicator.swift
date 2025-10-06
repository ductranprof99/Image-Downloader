//
//  RequestDeduplicator.swift
//  ImageDownloader
//
//  Prevents duplicate concurrent requests for the same URL
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Manages request deduplication to prevent multiple simultaneous downloads for the same URL
class RequestDeduplicator {

    // MARK: - Properties

    /// Maps URL to pending task
    /// Multiple callers can attach to the same pending task
    private var pendingTasks: [String: NetworkTask] = [:]

    /// Isolation queue for thread safety
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.deduplicator.isolation")

    // MARK: - Public Methods

    /// Check if a request should be executed or if there's already a pending task
    /// - Parameter url: The URL to check
    /// - Returns: Existing NetworkTask if found, nil otherwise
    func existingTask(for url: URL) -> NetworkTask? {
        isolationQueue.sync {
            pendingTasks[url.absoluteString]
        }
    }

    /// Register a new task as pending
    /// - Parameters:
    ///   - task: The NetworkTask to register
    ///   - url: The URL for the task
    func registerTask(_ task: NetworkTask, for url: URL) {
        isolationQueue.sync {
            pendingTasks[url.absoluteString] = task
        }
    }

    /// Remove a task from pending tasks (should be called when task completes)
    /// - Parameter url: The URL to remove
    func removeTask(for url: URL) {
        isolationQueue.sync {
            pendingTasks.removeValue(forKey: url.absoluteString)
        }
    }

    /// Get the number of pending tasks
    var pendingTaskCount: Int {
        isolationQueue.sync {
            pendingTasks.count
        }
    }

    /// Clear all pending tasks
    func clear() {
        isolationQueue.sync {
            pendingTasks.removeAll()
        }
    }
}
