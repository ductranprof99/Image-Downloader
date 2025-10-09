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
                .disableSaveToStorage()
                .enableDebugLogging()
                .build()
        case .withStorage:
            return ConfigBuilder()
                .enableSaveToStorage()
                .enableDebugLogging()
                .build()
        }
    }
    
    var message: String {
        switch self {
        case .noStorage:
            "Images loaded from disk storage only. Many"
        case .withStorage:
            "Images loaded from disk storage only. No network requests."
        }
    }
    
    var downloadPriority: DownloadPriority {
        return .high
    }
}
