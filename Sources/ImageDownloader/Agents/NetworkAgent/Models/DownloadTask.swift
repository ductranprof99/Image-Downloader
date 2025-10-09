//
//  DownloadTask.swift
//  ImageDownloader
//
//  Represents an active download task with waiters
//

import Foundation

/// Represents an active download task
internal final class DownloadTask {
    let url: URL
    let priority: DownloadPriority
    let startTime: Date
    var urlSessionTask: URLSessionDataTask?

    private let lock = NSLock()
    private var waiters: [(completion: InternalDownloadCompletionHandler,
                           progress: DownloadProgressHandler?)] = []

    init(url: URL, priority: DownloadPriority) {
        self.url = url
        self.priority = priority
        self.startTime = Date()
    }

    func addWaiter(completion: @escaping InternalDownloadCompletionHandler, progress: DownloadProgressHandler?) {
        lock.lock()
        waiters.append((completion, progress))
        lock.unlock()
    }

    func notifyAllWaiters(data: Data?, error: Error?) {
        lock.lock()
        let currentWaiters = waiters
        waiters.removeAll()
        lock.unlock()

        for waiter in currentWaiters {
            waiter.completion(data, error)
        }
    }

    func notifyProgress(_ progress: DownloadProgress) {
        lock.lock()
        let currentWaiters = waiters
        lock.unlock()

        for waiter in currentWaiters {
            waiter.progress?(progress)
        }
    }

    func cancel() {
        urlSessionTask?.cancel()
    }
}
