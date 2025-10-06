//
//  NetworkAgent.swift
//  ImageDownloader
//
//  Manages concurrent image downloads with priority queuing
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif


class NetworkAgent: NSObject {

    // MARK: - Properties

    var maxConcurrentDownloads: Int

    private let queue: NetworkQueue
    private var session: URLSession!
    private var activeDownloads: [String: NetworkTask] = [:]
    private var allTasks: [String: NetworkTask] = [:]
    private var taskMap: [Int: NetworkTask] = [:]
    private var dataMap: [Int: NSMutableData] = [:]
    private var expectedLengthMap: [Int: Int64] = [:]
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.networkagent.isolation")

    // MARK: - Initialization

    init(maxConcurrentDownloads: Int = 4) {
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.queue = NetworkQueue()
        super.init()

        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public Methods

    // MARK: Completion Handler API

    func downloadResource(
        at url: URL,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)? = nil,
        completion: ((UIImage?, Error?) -> Void)? = nil,
        caller: AnyObject? = nil
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let urlKey = url.absoluteString
            let existingTask = self.allTasks[urlKey]

            if let existingTask = existingTask {
                // Task already exists, just add callback
                existingTask.addCallback(
                    queue: .main,
                    progress: progress,
                    completion: completion,
                    caller: caller
                )
            } else {
                // Create new task
                let task = NetworkTask(url: url, priority: priority)
                task.addCallback(
                    queue: .main,
                    progress: progress,
                    completion: completion,
                    caller: caller
                )

                self.allTasks[urlKey] = task
                self.queue.enqueue(task)

                // Try to start downloads
                self.processQueue()
            }
        }
    }

    // MARK: Async/Await API (Swift Concurrency)

    /// Downloads an image resource asynchronously using async/await
    /// - Parameters:
    ///   - url: The URL of the image to download
    ///   - priority: The priority level for the download task
    ///   - progress: Optional progress callback (called on main queue)
    /// - Returns: The downloaded UIImage
    /// - Throws: ImageDownloaderError if the download fails
    @available(iOS 13.0, macOS 10.15, *)
    func downloadResource(
        at url: URL,
        priority: ResourcePriority,
        progress: ((CGFloat) -> Void)? = nil
    ) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let lock = NSLock()

            downloadResource(
                at: url,
                priority: priority,
                progress: progress,
                completion: { [weak self] image, error in
                    lock.lock()
                    defer { lock.unlock() }

                    // Ensure we only resume once
                    guard !hasResumed else { return }
                    hasResumed = true

                    if let error = error {
                        // Convert NSError to ImageDownloaderError
                        let downloadError = self?.convertToImageDownloaderError(error) ?? ImageDownloaderError.unknown(error)
                        continuation.resume(throwing: downloadError)
                    } else if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        // No image and no error - this shouldn't happen, but handle it
                        continuation.resume(throwing: ImageDownloaderError.unknown(
                            NSError(
                                domain: "ImageDownloader.NetworkAgent",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Unknown error: no image or error returned"]
                            )
                        ))
                    }
                },
                caller: nil
            )
        }
    }

    // MARK: - Error Conversion

    private func convertToImageDownloaderError(_ error: Error) -> ImageDownloaderError {
        // If it's already an ImageDownloaderError, return it
        if let imageError = error as? ImageDownloaderError {
            return imageError
        }

        // Check for NSError with specific codes
        let nsError = error as NSError

        // Check for cancellation
        if nsError.code == NSURLErrorCancelled || nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
            return .cancelled
        }

        // Check for timeout
        if nsError.code == NSURLErrorTimedOut {
            return .timeout
        }

        // Check for not found
        if nsError.code == NSURLErrorFileDoesNotExist || nsError.code == NSURLErrorBadURL {
            return .notFound
        }

        // Check for decoding failures (our custom error)
        if nsError.domain == "ImageDownloader.NetworkAgent" && nsError.code == -2 {
            return .decodingFailed
        }

        // Check if it's a network-related error
        if nsError.domain == NSURLErrorDomain {
            return .networkError(error)
        }

        // Default to unknown error
        return .unknown(error)
    }

    func cancelDownload(for url: URL, caller: AnyObject?) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let urlKey = url.absoluteString
            guard let task = self.allTasks[urlKey] else { return }

            if let caller = caller {
                task.removeCallbacks(for: caller)

                // If no more callbacks, cancel the task
                if task.callbackCount == 0 {
                    task.cancel()
                    self.activeDownloads.removeValue(forKey: urlKey)
                    self.queue.remove(task)
                    self.allTasks.removeValue(forKey: urlKey)

                    // Process queue to start next task
                    self.processQueue()
                }
            }
        }
    }

    func cancelAllDownloads(for url: URL) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let urlKey = url.absoluteString
            guard let task = self.allTasks[urlKey] else { return }

            task.cancel()
            self.activeDownloads.removeValue(forKey: urlKey)
            self.queue.remove(task)
            self.allTasks.removeValue(forKey: urlKey)

            // Process queue to start next task
            self.processQueue()
        }
    }

    var activeDownloadCount: Int {
        isolationQueue.sync {
            activeDownloads.count
        }
    }

    var queuedTaskCount: Int {
        queue.totalCount
    }

    // MARK: - Private Methods

    private func processQueue() {
        // Must be called on isolationQueue
        while activeDownloads.count < maxConcurrentDownloads && !queue.isEmpty {
            if let task = queue.dequeue() {
                startDownloadTask(task)
            }
        }
    }

    private func startDownloadTask(_ task: NetworkTask) {
        // Must be called on isolationQueue
        let urlKey = task.url.absoluteString
        activeDownloads[urlKey] = task

        // Create data task (will use delegate methods for progress)
        let sessionTask = session.dataTask(with: task.url)

        // Map session task to our task for delegate callbacks
        let taskID = sessionTask.taskIdentifier
        taskMap[taskID] = task
        dataMap[taskID] = NSMutableData()

        task.sessionTask = sessionTask
        sessionTask.resume()
    }
}

// MARK: - URLSessionDataDelegate

extension NetworkAgent: URLSessionDataDelegate {

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let taskID = dataTask.taskIdentifier

            // Store expected content length
            if let httpResponse = response as? HTTPURLResponse {
                self.expectedLengthMap[taskID] = httpResponse.expectedContentLength
            }

            // Reset data buffer
            self.dataMap[taskID] = NSMutableData()
        }

        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let taskID = dataTask.taskIdentifier
            guard let task = self.taskMap[taskID],
                  let accumulatedData = self.dataMap[taskID] else { return }

            // Accumulate data
            accumulatedData.append(data)

            // Calculate progress
            if let expectedLength = self.expectedLengthMap[taskID], expectedLength > 0 {
                let progress = min(CGFloat(accumulatedData.length) / CGFloat(expectedLength), 1.0)

                // Update task progress - this will notify all callbacks
                task.updateProgress(progress)
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task sessionTask: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            let taskID = sessionTask.taskIdentifier
            guard let task = self.taskMap[taskID] else { return }

            let data = self.dataMap[taskID]
            let urlKey = task.url.absoluteString

            var image: UIImage?
            var finalError = error

            if let data = data as Data?, error == nil {
                image = UIImage(data: data)
                if image == nil {
                    finalError = NSError(
                        domain: "ImageDownloader.NetworkAgent",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"]
                    )
                }
            }

            // Complete the task - this will notify all callbacks
            task.complete(with: image, error: finalError)

            // Cleanup
            self.activeDownloads.removeValue(forKey: urlKey)
            self.allTasks.removeValue(forKey: urlKey)
            self.taskMap.removeValue(forKey: taskID)
            self.dataMap.removeValue(forKey: taskID)
            self.expectedLengthMap.removeValue(forKey: taskID)

            // Start next task in queue
            self.processQueue()
        }
    }
}
