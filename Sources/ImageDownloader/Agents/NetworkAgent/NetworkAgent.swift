//
//  NetworkAgent.swift
//  ImageDownloader
//
//  Manages concurrent image downloads with modern async/await
//  Uses Swift Actor for thread-safe concurrency control
//  Uses a single shared URLSession for efficiency
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// NetworkAgent handles image downloads with automatic concurrency limiting and request deduplication
/// All state is actor-isolated for thread safety without DispatchQueue
/// Uses a single shared URLSession across all instances for resource efficiency
internal actor NetworkAgent {

    // MARK: - Shared Resources

    /// Shared URLSession instance used by all NetworkAgent instances
    /// This is more efficient than creating multiple sessions
    private static let sharedSession: URLSession = {
        let config = URLSessionConfiguration.default

        // Enable background network access (URLSession handles this properly)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false  // Download even when battery is low

        // Reasonable defaults
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300  // 5 minutes total
        config.httpMaximumConnectionsPerHost = 6
        config.allowsCellularAccess = true

        // Create with delegate for auth challenges
        return URLSession(configuration: config, delegate: SessionDelegate.shared, delegateQueue: nil)
    }()

    // MARK: - Configuration Properties

    var maxConcurrentDownloads: Int
    var timeout: TimeInterval
    var retryPolicy: RetryPolicy
    var customHeaders: [String: String]?
    var authenticationHandler: ((inout URLRequest) -> Void)?
    var allowsCellularAccess: Bool

    // MARK: - Private State

    /// Active downloads: URL -> DownloadOperation
    /// Provides automatic request deduplication - multiple requests for same URL share one download
    private var activeDownloads: [String: DownloadOperation] = [:]

    /// Pending downloads waiting for slot (FIFO queue with priority)
    private var pendingQueue: [PendingDownload] = []

    // MARK: - Initialization

    init(config: NetworkConfig) {
        self.maxConcurrentDownloads = config.maxConcurrentDownloads
        self.timeout = config.timeout
        self.retryPolicy = config.retryPolicy
        self.customHeaders = config.customHeaders
        self.authenticationHandler = config.authenticationHandler
        self.allowsCellularAccess = config.allowsCellularAccess
    }

    // MARK: - Public API (Non-isolated for sync access)

    /// Download an image using completion handler (backwards compatible)
    nonisolated func downloadResource(
        at url: URL,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)? = nil,
        completion: ((UIImage?, Error?) -> Void)?
    ) {
        Task {
            do {
                let image = try await downloadResource(at: url, priority: priority, progress: progress)
                completion?(image, nil)
            } catch {
                completion?(nil, error)
            }
        }
    }

    /// Cancel download for specific URL
    nonisolated func cancelDownload(for url: URL) {
        Task {
            await _cancelDownload(for: url)
        }
    }

    // MARK: - Public API (Actor-isolated async methods)

    /// Download an image using pure async/await
    /// Automatically handles:
    /// - Request deduplication (multiple requests for same URL share one download)
    /// - Concurrency limiting (respects maxConcurrentDownloads)
    /// - Priority queueing (high priority requests processed first)
    func downloadResource(
        at url: URL,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)? = nil
    ) async throws -> UIImage {
        let urlKey = url.absoluteString

        // REQUEST DEDUPLICATION: Check if already downloading
        if let existingOperation = activeDownloads[urlKey] {
            // Join existing download instead of starting new one
            return try await existingOperation.task.value
        }

        // CONCURRENCY LIMITING: Check if we have available slots
        if activeDownloads.count >= maxConcurrentDownloads {
            // Queue is full - wait in pending queue
            return try await withCheckedThrowingContinuation { continuation in
                let pending = PendingDownload(
                    url: url,
                    priority: priority,
                    continuation: continuation,
                    progress: progress
                )

                // Insert based on priority (high priority first)
                if priority == .high {
                    // Find first low priority item and insert before it
                    if let index = pendingQueue.firstIndex(where: { $0.priority == .low }) {
                        pendingQueue.insert(pending, at: index)
                    } else {
                        pendingQueue.append(pending)
                    }
                } else {
                    pendingQueue.append(pending)
                }
            }
        }

        // Start new download
        return try await startDownload(url: url, priority: priority, progress: progress)
    }

    /// Get statistics
    var activeDownloadCount: Int {
        get async {
            activeDownloads.count
        }
    }

    var pendingDownloadCount: Int {
        get async {
            pendingQueue.count
        }
    }

    // MARK: - Private Methods

    /// Start a new download (assumes slot is available)
    private func startDownload(
        url: URL,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)?
    ) async throws -> UIImage {
        let urlKey = url.absoluteString

        // Create download task
        let downloadTask = Task(priority: priority.taskPriority) { [weak self] () -> UIImage in
            guard let self = self else {
                throw ImageDownloaderError.unknown(
                    NSError(domain: "ImageDownloader.NetworkAgent", code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "NetworkAgent was deallocated"])
                )
            }

            return try await self.performDownload(url: url, retryAttempt: 0, progress: progress)
        }

        // Track the operation
        let operation = DownloadOperation(url: url, priority: priority, task: downloadTask)
        activeDownloads[urlKey] = operation

        // Wait for completion
        do {
            let image = try await downloadTask.value

            // Cleanup
            activeDownloads.removeValue(forKey: urlKey)

            // Process next pending download
            await processNextPending()

            return image

        } catch {
            // Cleanup on error
            activeDownloads.removeValue(forKey: urlKey)

            // Process next pending download
            await processNextPending()

            throw error
        }
    }

    /// Process next pending download if slot available
    /// FIXED: Now properly async to avoid continuation leaks
    private func processNextPending() async {
        // Check if we have capacity and pending downloads
        guard activeDownloads.count < maxConcurrentDownloads,
              !pendingQueue.isEmpty else {
            return
        }

        // Dequeue next pending download
        let pending = pendingQueue.removeFirst()

        // FIXED: Use structured concurrency - ensure continuation is ALWAYS resumed
        do {
            let image = try await startDownload(
                url: pending.url,
                priority: pending.priority,
                progress: pending.progress
            )
            pending.continuation.resume(returning: image)
        } catch {
            pending.continuation.resume(throwing: error)
        }
    }

    /// Perform the actual download with retry logic
    /// Uses shared URLSession with per-request configuration
    private func performDownload(
        url: URL,
        retryAttempt: Int,
        progress: ((CGFloat) -> Void)?
    ) async throws -> UIImage {
        // Build request with per-request configuration
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout  // Per-request timeout
        request.allowsCellularAccess = allowsCellularAccess  // Per-request cellular access
        request.cachePolicy = .reloadIgnoringLocalCacheData  // Always fetch fresh

        // Apply custom headers
        if let customHeaders = customHeaders {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Apply authentication handler
        authenticationHandler?(&request)

        do {
            // Execute download using SHARED URLSession with configured request
            let (data, response) = try await Self.sharedSession.data(for: request)

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageDownloaderError.networkError(
                    NSError(domain: "ImageDownloader", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                )
            }

            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 404 {
                    throw ImageDownloaderError.notFound
                } else {
                    throw ImageDownloaderError.networkError(
                        NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                    )
                }
            }

            // Decode image
            guard let image = UIImage(data: data) else {
                throw ImageDownloaderError.decodingFailed
            }

            // Report completion
            progress?(1.0)

            return image

        } catch {
            // RETRY LOGIC: Check if should retry
            if retryPolicy.shouldRetry(for: error, attempt: retryAttempt, url: url) {
                let delay = retryPolicy.delay(forAttempt: retryAttempt + 1)

                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Check cancellation
                try Task.checkCancellation()

                // Recursive retry
                return try await performDownload(url: url, retryAttempt: retryAttempt + 1, progress: progress)
            }

            // Convert and throw error
            throw convertToImageDownloaderError(error)
        }
    }

    /// Cancel download for specific URL
    private func _cancelDownload(for url: URL) {
        let urlKey = url.absoluteString

        // Cancel active download
        if let operation = activeDownloads[urlKey] {
            operation.task.cancel()
            activeDownloads.removeValue(forKey: urlKey)

            // Process next pending (spawn task to avoid blocking)
            Task {
                await processNextPending()
            }
            return
        }

        // Remove from pending queue and resume with cancellation error
        pendingQueue.removeAll { pending in
            if pending.url.absoluteString == urlKey {
                // FIXED: Resume continuation with cancellation before removing
                pending.continuation.resume(throwing: ImageDownloaderError.cancelled)
                return true
            }
            return false
        }
    }

    /// Convert NSError to ImageDownloaderError
    private func convertToImageDownloaderError(_ error: Error) -> ImageDownloaderError {
        if let imageError = error as? ImageDownloaderError {
            return imageError
        }

        let nsError = error as NSError

        // Cancellation
        if nsError.code == NSURLErrorCancelled ||
           (nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) {
            return .cancelled
        }

        // Timeout
        if nsError.code == NSURLErrorTimedOut {
            return .timeout
        }

        // Not found
        if nsError.code == NSURLErrorFileDoesNotExist || nsError.code == NSURLErrorBadURL {
            return .notFound
        }

        // Network error
        if nsError.domain == NSURLErrorDomain {
            return .networkError(error)
        }

        return .unknown(error)
    }

    // MARK: - Cleanup

    func cleanup() {
        // Cancel all active downloads
        for (_, operation) in activeDownloads {
            operation.task.cancel()
        }
        activeDownloads.removeAll()

        // FIXED: Resume all pending continuations before clearing
        for pending in pendingQueue {
            pending.continuation.resume(throwing: ImageDownloaderError.cancelled)
        }
        pendingQueue.removeAll()
    }
}

// MARK: - Supporting Extensions

extension ResourcePriority {
    var taskPriority: TaskPriority {
        switch self {
        case .high:
            return .high
        case .low:
            return .low
        }
    }
}

// MARK: - Session Delegate

/// Shared URLSession delegate for handling authentication challenges
/// Singleton pattern since URLSession is shared across all NetworkAgent instances
private class SessionDelegate: NSObject, URLSessionDelegate {

    static let shared = SessionDelegate()

    private override init() {
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Handle authentication challenges if needed
        // Default: perform default handling (trust system certificates)
        completionHandler(.performDefaultHandling, nil)
    }
}
