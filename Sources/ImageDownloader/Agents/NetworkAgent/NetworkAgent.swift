//
//  NetworkAgent.swift
//  ImageDownloader
//
//  Manages concurrent downloads with GCD for thread safety
//  Downloads RAW DATA only - image decoding is handled separately
//  Thread-safe using serial DispatchQueue
//  Fully ObjC compatible with callback-based API
//

import UIKit

/// Completion handler for downloads
typealias DownloadCompletionHandler = (UIImage?, Error?) -> Void
typealias InternalDownloadCompletionHandler = (Data?, Error?) -> Void
typealias DownloadProgressHandler = (DownloadProgress) -> Void

/// NetworkAgent handles data downloads with automatic concurrency limiting and request deduplication
/// Thread-safe using serial DispatchQueue
/// Downloads RAW DATA - image decoding handled separately
final class NetworkAgent: NSObject {

    // MARK: - Shared Resources

    /// Shared URLSession instance used by all NetworkAgent instances
    private static let sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpMaximumConnectionsPerHost = 6
        config.allowsCellularAccess = true

        return URLSession(configuration: config, delegate: SessionDelegate.shared, delegateQueue: nil)
    }()

    // MARK: - Configuration Properties

    private var maxConcurrentDownloads: Int
    private var timeout: TimeInterval
    private var retryPolicy: RetryPolicy
    private var customHeaders: [String: String]?
    private var authenticationHandler: ((inout URLRequest) -> Void)?
    private var allowsCellularAccess: Bool

    // MARK: - Thread Safety

    /// Serial queue for thread-safe access to internal state
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.networkagent.isolation", qos: .userInitiated)

    // MARK: - Private State (Access only via isolationQueue)

    /// Active downloads: URL -> DownloadTask
    private var activeDownloads: [String: DownloadTask] = [:]

    /// Pending downloads waiting for slot (FIFO queue with priority)
    private var pendingQueue: [PendingDownloadRequest] = []

    // MARK: - Initialization

    init(config: NetworkConfig) {
        self.maxConcurrentDownloads = config.maxConcurrentDownloads
        self.timeout = config.timeout
        self.retryPolicy = config.retryPolicy
        self.customHeaders = config.customHeaders
        self.authenticationHandler = config.authenticationHandler
        self.allowsCellularAccess = config.allowsCellularAccess
        super.init()
    }

    // MARK: - Downloader agent api
    /// Download data with priority (ObjC compatible)
    func downloadData(
        at url: URL,
        priority: DownloadPriority = .high,
        progress: DownloadProgressHandler? = nil,
        completion: @escaping DownloadCompletionHandler
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else {
                completion(nil, ImageDownloaderError.unknown(
                    NSError(domain: "NetworkAgent", code: -1, userInfo: [NSLocalizedDescriptionKey: "NetworkAgent deallocated"])
                ))
                return
            }

            let urlKey = url.absoluteString

            // REQUEST DEDUPLICATION: Check if already downloading
            if let existingTask = self.activeDownloads[urlKey] {
                // Join existing download - decode will happen when data arrives
                existingTask.addWaiter(
                    completion: { data, error in
                        // Decode image
                        guard let imageData = data,
                              let image = ImageDecoder.decodeImage(from: imageData) else {
                            completion(nil, error)
                            return
                        }
                        completion(image, error)
                    },
                    progress: progress)
                return
            }

            // CONCURRENCY LIMITING: Check if we have available slots
            if self.activeDownloads.count >= self.maxConcurrentDownloads {
                // Queue is full - add to pending queue
                let pending = PendingDownloadRequest(
                    url: url,
                    priority: priority,
                    progress: progress,
                    completion: completion
                )

                // Insert based on priority
                if priority == .high {
                    if let index = self.pendingQueue.firstIndex(where: { $0.priority == .low }) {
                        self.pendingQueue.insert(pending, at: index)
                    } else {
                        self.pendingQueue.append(pending)
                    }
                } else {
                    self.pendingQueue.append(pending)
                }
                return
            }

            // Start new download
            self.startDownloadUnsafe(url: url, priority: priority, progress: progress, completion: completion)
        }
    }

    /// Cancel download for specific URL (ObjC compatible)
    func cancelDownload(for url: URL) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let urlKey = url.absoluteString

            // Cancel active download
            if let task = self.activeDownloads[urlKey] {
                task.cancel()
                self.activeDownloads.removeValue(forKey: urlKey)

                // Notify all waiters
                let error = ImageDownloaderError.cancelled
                task.notifyAllWaiters(data: nil, error: error)

                // Process next pending
                self.processNextPendingUnsafe()
                return
            }

            // Remove from pending queue
            self.pendingQueue.removeAll { pending in
                if pending.url.absoluteString == urlKey {
                    pending.completion(nil, ImageDownloaderError.cancelled)
                    return true
                }
                return false
            }
        }
    }

    // MARK: - Statistics (ObjC Compatible)

    var activeDownloadCount: Int {
        var count = 0
        isolationQueue.sync {
            count = activeDownloads.count
        }
        return count
    }

    var pendingDownloadCount: Int {
        var count = 0
        isolationQueue.sync {
            count = pendingQueue.count
        }
        return count
    }

    // MARK: - Private Methods (Must be called on isolationQueue)

    /// Start a new download (must be called on isolationQueue)
    private func startDownloadUnsafe(
        url: URL,
        priority: DownloadPriority,
        progress: DownloadProgressHandler?,
        completion: @escaping DownloadCompletionHandler
    ) {
        let urlKey = url.absoluteString
        
        // Create download task
        let downloadTask = DownloadTask(url: url, priority: priority)
        downloadTask.addWaiter(
            completion: { data, error in
                // Decode image
                guard let imageData = data,
                      let image = ImageDecoder.decodeImage(from: imageData) else {
                    completion(nil, error)
                    return
                }
                completion(image, error)
            },
            progress: progress)
        activeDownloads[urlKey] = downloadTask
        
        // Perform download on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.performDownload(
                url: url,
                retryAttempt: 0,
                task: downloadTask
            ) { data, error in
                // Handle completion on isolation queue
                self.isolationQueue.async {
                    self.activeDownloads.removeValue(forKey: urlKey)

                    // Notify all waiters
                    downloadTask.notifyAllWaiters(data: data, error: error)

                    // Process next pending download
                    self.processNextPendingUnsafe()
                }
            }
        }
    }

    /// Process next pending download if slot available (must be called on isolationQueue)
    private func processNextPendingUnsafe() {
        guard activeDownloads.count < maxConcurrentDownloads,
              !pendingQueue.isEmpty else {
            return
        }

        let pending = pendingQueue.removeFirst()

        if pending.isExpired {
            pending.completion(nil, ImageDownloaderError.timeout)
            processNextPendingUnsafe()
            return
        }

        startDownloadUnsafe(
            url: pending.url,
            priority: pending.priority,
            progress: pending.progress,
            completion: pending.completion
        )
    }

    /// Perform the actual download with retry logic
    private func performDownload(
        url: URL,
        retryAttempt: Int,
        task: DownloadTask,
        completion: @escaping InternalDownloadCompletionHandler
    ) {
        // Build request
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.allowsCellularAccess = allowsCellularAccess
        request.cachePolicy = .reloadIgnoringLocalCacheData

        // Apply custom headers
        if let customHeaders = customHeaders {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Apply authentication handler
        authenticationHandler?(&request)

        let startTime = Date()

        // Create URLSession task
        let urlSessionTask = Self.sharedSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(nil, ImageDownloaderError.unknown(
                    NSError(domain: "NetworkAgent", code: -1, userInfo: nil)
                ))
                return
            }

            // Handle error
            if let error = error {
                // Check if should retry
                if self.retryPolicy.shouldRetry(for: error, attempt: retryAttempt, url: url) {
                    let delay = self.retryPolicy.delay(forAttempt: retryAttempt + 1)

                    // Retry after delay
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
                        self.performDownload(url: url, retryAttempt: retryAttempt + 1, task: task, completion: completion)
                    }
                    return
                }

                // No retry - fail
                completion(nil, self.convertToImageDownloaderError(error))
                return
            }

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, ImageDownloaderError.networkError(
                    NSError(domain: "ImageDownloader", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                ))
                return
            }

            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 404 {
                    completion(nil, ImageDownloaderError.notFound)
                } else {
                    completion(nil, ImageDownloaderError.networkError(
                        NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                    ))
                }
                return
            }

            // Validate data
            guard let data = data else {
                completion(nil, ImageDownloaderError.networkError(
                    NSError(domain: "ImageDownloader", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No data received"])
                ))
                return
            }

            // Report final progress
            let totalBytes = Int64(data.count)
            let totalTime = Date().timeIntervalSince(startTime)
            let avgSpeed = totalTime > 0 ? Double(totalBytes) / totalTime : 0

            let finalProgress = DownloadProgress(
                bytesDownloaded: totalBytes,
                totalBytes: totalBytes,
                speed: avgSpeed
            )

            DispatchQueue.main.async {
                task.notifyProgress(finalProgress)
            }

            completion(data, nil)
        }

        // Store task for cancellation
        task.urlSessionTask = urlSessionTask

        // Start download
        urlSessionTask.resume()
    }

    /// Convert NSError to ImageDownloaderError
    private func convertToImageDownloaderError(_ error: Error) -> ImageDownloaderError {
        if let imageError = error as? ImageDownloaderError {
            return imageError
        }

        let nsError = error as NSError

        if nsError.code == NSURLErrorCancelled ||
           (nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) {
            return .cancelled
        }

        if nsError.code == NSURLErrorTimedOut {
            return .timeout
        }

        if nsError.code == NSURLErrorFileDoesNotExist || nsError.code == NSURLErrorBadURL {
            return .notFound
        }

        if nsError.domain == NSURLErrorDomain {
            return .networkError(error)
        }

        return .unknown(error)
    }

    // MARK: - Cleanup

    func cleanup() {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            // Cancel all active downloads
            for (_, task) in self.activeDownloads {
                task.cancel()
                task.notifyAllWaiters(data: nil, error: ImageDownloaderError.cancelled)
            }
            self.activeDownloads.removeAll()

            // Clear pending queue
            for pending in self.pendingQueue {
                pending.completion(nil, ImageDownloaderError.cancelled)
            }
            self.pendingQueue.removeAll()
        }
    }
}
