//
//  DownloadOperation.swift
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

import UIKit

/// Represents an active download operation
struct DownloadOperation {
        let url: URL
        let priority: ResourcePriority
        let task: Task<UIImage, Error>
        let startTime: Date

        init(url: URL, priority: ResourcePriority, task: Task<UIImage, Error>) {
            self.url = url
            self.priority = priority
            self.task = task
            self.startTime = Date()
        }
    }
