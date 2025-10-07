//
//  CompressionType.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import Foundation

enum CompressionType {
    case png
    case jpeg
    case adaptive
}

enum PathProviderType {
    case flat
    case domain
    case date
}

struct StorageFileInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: UInt64
    let modificationDate: Date

    var sizeString: String {
        let kb = Double(size) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024
            return String(format: "%.2f MB", mb)
        }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
}
