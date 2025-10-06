//
//  BackgroundTaskManager.swift
//  ImageDownloader
//
//  Manages UIKit background tasks for downloads
//

#if canImport(UIKit)
import UIKit
import Foundation

/// Manages background task lifecycle for network operations
class BackgroundTaskManager {

    // MARK: - Properties

    private var activeBackgroundTasks: [URL: UIBackgroundTaskIdentifier] = [:]
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.backgroundtask.isolation")

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Begin a background task for a URL
    /// - Parameter url: The URL being downloaded
    func beginBackgroundTask(for url: URL) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            // Only create if one doesn't exist
            guard self.activeBackgroundTasks[url] == nil else { return }

            let taskID = UIApplication.shared.beginBackgroundTask(withName: "ImageDownload-\(url.absoluteString)") { [weak self] in
                // Expiration handler - clean up when time runs out
                self?.endBackgroundTask(for: url)
            }

            if taskID != .invalid {
                self.activeBackgroundTasks[url] = taskID
            }
        }
    }

    /// End a background task for a URL
    /// - Parameter url: The URL that finished downloading
    func endBackgroundTask(for url: URL) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            if let taskID = self.activeBackgroundTasks.removeValue(forKey: url) {
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }
    }

    /// End all active background tasks (e.g., when app is terminating)
    func endAllBackgroundTasks() {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            for (_, taskID) in self.activeBackgroundTasks {
                UIApplication.shared.endBackgroundTask(taskID)
            }
            self.activeBackgroundTasks.removeAll()
        }
    }

    /// Check if a background task is active for a URL
    /// - Parameter url: The URL to check
    /// - Returns: Whether a background task is active
    func hasBackgroundTask(for url: URL) -> Bool {
        isolationQueue.sync {
            return activeBackgroundTasks[url] != nil
        }
    }
}

#endif
