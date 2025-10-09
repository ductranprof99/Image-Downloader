//
//  StorageOnlyViewModel.swift
//  Storage
//
//  Created by ductd on 9/10/25.
//

import ImageDownloader
import SwiftUI

class StorageOnlyViewModel: ObservableObject {
    var storageItemsFixed: [URL] = []
    @Published var storedImagesDynamic: [URL] = []
    @Published var fetchItem: Int = 0
    @Published var downloadTask: Int = 0
    @Published var storedImageCount: Int = 0
    @Published var totalBytesCount: Double = 0.0
    @Published var storageMode: StorageMode = .noStorage {
        didSet {
            manager.configure(storageMode.configuration)
            manager.clearAllCache()
            storedImagesDynamic = []
            storedImageCount = 0
            totalBytesCount = 0
        }
    }
    
    private let manager = ImageDownloaderManager.shared
    
    init() {
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        totalBytesCount = mb
        storageItemsFixed = ImageItem.generateSampleData(count: 20).map { $0.url }
    }

    func reloadData() {
        // Get storage size
        fetchItem = storageItemsFixed.count
        storedImagesDynamic = storageItemsFixed
    }

    func refreshCache() {
        manager.clearAllCache()
        reloadData()
    }

    func clearStorage() {
        storedImagesDynamic = []
        manager.hardReset()
    }
}
