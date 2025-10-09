//
//  PendingDownloadRequest.swift
//  ImageDownloader
//
//  Represents a download request waiting in queue
//

import Foundation

/// Represents a pending download request waiting for a slot
internal struct PendingDownloadRequest {
    let url: URL
    let priority: DownloadPriority
    let progress: DownloadProgressHandler?
    let completion: DownloadCompletionHandler
    let enqueueTime: Date

    init(
        url: URL,
        priority: DownloadPriority,
        progress: DownloadProgressHandler?,
        completion: @escaping DownloadCompletionHandler
    ) {
        self.url = url
        self.priority = priority
        self.progress = progress
        self.completion = completion
        self.enqueueTime = Date()
    }
}
