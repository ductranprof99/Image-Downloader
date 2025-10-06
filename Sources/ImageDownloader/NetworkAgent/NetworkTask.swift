//
//  NetworkTask.swift
//  ImageDownloader
//
//  Represents a single network download task with multiple callbacks
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public enum NetworkTaskState {
    case new
    case downloading
    case completed
    case failed
    case cancelled
}

class NetworkTaskCallback {
    let queue: DispatchQueue
    let progressBlock: ((CGFloat) -> Void)?
    let completion: ((UIImage?, Error?) -> Void)?
    weak var caller: AnyObject?

    init(
        queue: DispatchQueue = .main,
        progress: ((CGFloat) -> Void)? = nil,
        completion: ((UIImage?, Error?) -> Void)? = nil,
        caller: AnyObject? = nil
    ) {
        self.queue = queue
        self.progressBlock = progress
        self.completion = completion
        self.caller = caller
    }
}

class NetworkTask {

    // MARK: - Properties

    let url: URL
    let priority: ResourcePriority
    private(set) var state: NetworkTaskState
    private(set) var progress: CGFloat
    var sessionTask: URLSessionDataTask?

    private var callbacks: [NetworkTaskCallback] = []
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.networktask.isolation")

    // MARK: - Initialization

    init(url: URL, priority: ResourcePriority) {
        self.url = url
        self.priority = priority
        self.state = .new
        self.progress = 0.0
    }

    // MARK: - Public Methods

    func addCallback(
        queue: DispatchQueue? = nil,
        progress: ((CGFloat) -> Void)? = nil,
        completion: ((UIImage?, Error?) -> Void)? = nil,
        caller: AnyObject? = nil
    ) {
        isolationQueue.sync {
            let callback = NetworkTaskCallback(
                queue: queue ?? .main,
                progress: progress,
                completion: completion,
                caller: caller
            )
            callbacks.append(callback)

            if state == .new {
                state = .downloading
            }
        }
    }

    func removeCallbacks(for caller: AnyObject) {
        isolationQueue.sync {
            callbacks.removeAll { $0.caller === caller }
        }
    }

    var callbackCount: Int {
        isolationQueue.sync {
            callbacks.count
        }
    }

    func updateProgress(_ progress: CGFloat) {
        isolationQueue.sync {
            self.progress = progress

            for callback in callbacks {
                callback.progressBlock.map { block in
                    callback.queue.async {
                        block(progress)
                    }
                }
            }
        }
    }

    func complete(with image: UIImage?, error: Error?) {
        isolationQueue.sync {
            state = image != nil ? .completed : .failed

            for callback in callbacks {
                callback.completion.map { block in
                    callback.queue.async {
                        block(image, error)
                    }
                }
            }

            callbacks.removeAll()
        }
    }

    func cancel() {
        isolationQueue.sync {
            state = .cancelled

            sessionTask?.cancel()
            sessionTask = nil

            callbacks.removeAll()
        }
    }
}
