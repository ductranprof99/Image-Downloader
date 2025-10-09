//
//  LoadStats.swift
//  NetworkDownloader
//
//  Created by ductd on 9/10/25.
//


import Foundation

struct LoadStats {
    let loadTime: TimeInterval
    let speed: CGFloat
    let size: CGFloat
    let source: String
    let retryCount: Int

    var loadTimeString: String {
        String(format: "%.2fs", loadTime)
    }
}
