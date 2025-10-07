//
//  StorageOnlyViewModel.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import ImageDownloader
import SwiftUI

class StorageOnlyViewModel: ObservableObject {
    @Published var storedImages: [URL] = []
    @Published var storedImageCount: Int = 0
    @Published var storageSizeString: String = "0 MB"
    @AppStorage("storageMode") var storageMode: StorageMode = .noStorage
    
    private let manager = ImageDownloaderManager.shared
    private var loadingTasks: [URL: Task<Void, Never>] = [:]
    
    deinit {
        // Cancel all pending tasks
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
        
        // Clear cache when view model is deallocated
        Task {
            await manager.clearLowPriorityCache()
        }
    }

    func loadStorageInfo() {
        // Get storage size
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        storageSizeString = String(format: "%.2f MB", mb)

        // For demo purposes, we'll use sample URLs
        // In production, you'd track which URLs are actually stored
        storedImages = ImageItem.generateSampleData(count: 20).map { $0.url }
        storedImageCount = storedImages.count
    }

    func refreshStorageInfo() {
        loadStorageInfo()
    }

    func clearStorage() {
        manager.clearStorage { [weak self] success in
            
            DispatchQueue.main.async {
                if success {
                    self?.storedImages = []
                    self?.storedImageCount = 0
                    self?.storageSizeString = "0 MB"
                }
            }
        }
    }
}
