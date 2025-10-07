//
//  PendingDownload.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import UIKit

/// Represents a pending download waiting for a slot
struct PendingDownload {
        let url: URL
        let priority: ResourcePriority
        let continuation: CheckedContinuation<UIImage, Error>
        let progress: ((CGFloat) -> Void)?
        let enqueueTime: Date

        init(url: URL, priority: ResourcePriority,
             continuation: CheckedContinuation<UIImage, Error>,
             progress: ((CGFloat) -> Void)?) {
            self.url = url
            self.priority = priority
            self.continuation = continuation
            self.progress = progress
            self.enqueueTime = Date()
        }
    }
