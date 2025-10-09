//
//  StorageOnlyViewModel.swift
//  Storage
//
//  Created by ductd on 9/10/25.
//

import ImageDownloader
import SwiftUI

final class StorageOnlyViewModel: ObservableObject {
    var storageItemsFixed: [URL] = []
    @Published var storedImagesDynamic: [URL] = []
    @Published var fetchItem: Int = 0
    @Published var downloadTask: Int = 0
    @Published var storedImageCount: Int = 0 {
        didSet {
            storedImageCountString = "\(storedImageCount)"
        }
    }
    @Published var storedImageCountString: String = ""
    @Published var totalBytesCount: Double = 0.0 {
        didSet {
            totalBytesCountString = "\(totalBytesCount) Mb"
        }
    }
    @Published var totalBytesCountString: String = ""
    // Changing this forces SwiftUI to recreate views showing cached state
    @Published var refreshKey: UUID = UUID()
    @AppStorage("mode") var storageMode: StorageMode = .noStorage {
        didSet {
            manager.configure(storageMode.configuration)
            storedImagesDynamic = []
            storedImageCount = 0
            totalBytesCount = 0
            refreshKey = UUID()
        }
    }
    
    private let manager = ImageDownloaderManager.shared
    
    init() {
        manager.configure(storageMode.configuration)
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        totalBytesCount = mb
//        storageItemsFixed = ImageItem.generateSampleData(count: 20).map { $0.url }
        storageItemsFixed = ImageItem.fixedData().map { $0.url }
    }

    func reloadData() {
        // Get storage size
        fetchItem = storageItemsFixed.count
        storedImagesDynamic = storageItemsFixed
    }
    
    func clearTempCache() {
        manager.clearAllCache()
    }

    func refreshCache() {
        manager.clearAllCache()
        storedImagesDynamic = []
        // Bump key to force view recreation so @State images reset
        refreshKey = UUID()
        reloadData()
    }

    func clearStorage() {
        storedImagesDynamic = []
        manager.hardReset()
        // Ensure any existing image views are invalidated
        refreshKey = UUID()
    }
}
