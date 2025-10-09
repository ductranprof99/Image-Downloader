//
//  StorageMode.swift
//  Storage
//
//  Created by ductd on 9/10/25.
//

import ImageDownloader

enum StorageMode: Int, CaseIterable {
    case noStorage = 0
    case withStorage = 1
    
    var description: String {
        switch self {
        case .noStorage:
            return "No Storage"
        case .withStorage:
            return "Storage"
        }
    }
    
    var configuration: IDConfiguration {
        switch self {
        case .noStorage:
            return ConfigBuilder()
                .shouldSaveToStorage(false)
                .build()
        case .withStorage:
            return ConfigBuilder()
                .shouldSaveToStorage(true)
                .build()
        }
    }
    
    var downloadPriority: DownloadPriority {
        return .high
    }
}
