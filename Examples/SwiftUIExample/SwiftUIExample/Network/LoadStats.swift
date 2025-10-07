//
//  LoadStats.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import Foundation

struct LoadStats {
    let loadTime: TimeInterval
    let source: String
    let retryCount: Int

    var loadTimeString: String {
        String(format: "%.2fs", loadTime)
    }
}

