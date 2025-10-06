//
//  NetworkQueue.swift
//  ImageDownloader
//
//  Priority-based queue for network download tasks
//

import Foundation

class NetworkQueue {

    // MARK: - Properties

    private var highPriorityQueue: [NetworkTask] = []
    private var lowPriorityQueue: [NetworkTask] = []
    private var tasksByURL: [String: NetworkTask] = [:]
    private let isolationQueue = DispatchQueue(label: "com.imagedownloader.networkqueue.isolation")

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    func enqueue(_ task: NetworkTask) {
        isolationQueue.sync {
            // Check for duplicate URL
            let urlKey = task.url.absoluteString
            guard tasksByURL[urlKey] == nil else {
                return // Task already exists
            }

            // Add to appropriate priority queue
            if task.priority == .high {
                highPriorityQueue.append(task)
            } else {
                lowPriorityQueue.append(task)
            }

            tasksByURL[urlKey] = task
        }
    }

    func dequeue() -> NetworkTask? {
        isolationQueue.sync {
            var task: NetworkTask?

            // High priority first
            if !highPriorityQueue.isEmpty {
                task = highPriorityQueue.removeFirst()
            } else if !lowPriorityQueue.isEmpty {
                task = lowPriorityQueue.removeFirst()
            }

            if let task = task {
                tasksByURL.removeValue(forKey: task.url.absoluteString)
            }

            return task
        }
    }

    func peekNext() -> NetworkTask? {
        isolationQueue.sync {
            if !highPriorityQueue.isEmpty {
                return highPriorityQueue.first
            } else if !lowPriorityQueue.isEmpty {
                return lowPriorityQueue.first
            }
            return nil
        }
    }

    func task(for url: URL) -> NetworkTask? {
        isolationQueue.sync {
            tasksByURL[url.absoluteString]
        }
    }

    func remove(_ task: NetworkTask) {
        isolationQueue.sync {
            highPriorityQueue.removeAll { $0 === task }
            lowPriorityQueue.removeAll { $0 === task }
            tasksByURL.removeValue(forKey: task.url.absoluteString)
        }
    }

    var isEmpty: Bool {
        isolationQueue.sync {
            highPriorityQueue.isEmpty && lowPriorityQueue.isEmpty
        }
    }

    var highPriorityCount: Int {
        isolationQueue.sync {
            highPriorityQueue.count
        }
    }

    var lowPriorityCount: Int {
        isolationQueue.sync {
            lowPriorityQueue.count
        }
    }

    var totalCount: Int {
        isolationQueue.sync {
            highPriorityQueue.count + lowPriorityQueue.count
        }
    }

    func clearAll() {
        isolationQueue.sync {
            highPriorityQueue.removeAll()
            lowPriorityQueue.removeAll()
            tasksByURL.removeAll()
        }
    }
}
