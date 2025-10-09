//
//  DownloadProgress.swift
//  ImageDownloader
//
//  Rich download progress information
//

import Foundation

/// Rich download progress information with metadata
final class DownloadProgress: NSObject {
    /// Bytes downloaded so far
    let bytesDownloaded: Int64

    /// Total bytes to download (-1 if unknown)
    let totalBytes: Int64

    /// Progress ratio (0.0 - 1.0)
    let progress: Double

    /// Download speed in bytes per second
    let speed: Double

    /// Estimated time remaining in seconds (-1 if unknown)
    let estimatedTimeRemaining: TimeInterval

    /// Timestamp when this progress was captured
    let timestamp: Date

    init(
        bytesDownloaded: Int64,
        totalBytes: Int64,
        speed: Double,
        timestamp: Date = Date()
    ) {
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.speed = speed
        self.timestamp = timestamp

        // Calculate progress
        if totalBytes > 0 {
            self.progress = min(1.0, Double(bytesDownloaded) / Double(totalBytes))
        } else {
            self.progress = 0.0
        }

        // Calculate estimated time remaining
        if speed > 0 && totalBytes > 0 {
            let remainingBytes = totalBytes - bytesDownloaded
            self.estimatedTimeRemaining = Double(remainingBytes) / speed
        } else {
            self.estimatedTimeRemaining = -1
        }

        super.init()
    }

    /// Convenience initializer for simple progress (backward compatibility)
    convenience init(progress: Double) {
        self.init(
            bytesDownloaded: Int64(progress * 100),
            totalBytes: 100,
            speed: 0
        )
    }
}
