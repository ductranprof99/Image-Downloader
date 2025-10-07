//
//  FullFeaturedViewModel.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//
import SwiftUI
import ImageDownloader


class FullFeaturedViewModel: ObservableObject {
    @Published var imageItems: [ImageItem] = []
    @Published var cacheCount: Int = 0
    @Published var storageSizeString: String = "0 MB"
    @Published var activeDownloads: Int = 0

    private let manager = ImageDownloaderManager.shared
    private var refreshTimer: Timer?

    init() {
        startRefreshTimer()
    }

    func loadImages() {
        imageItems = ImageItem.generateSampleData(count: 30)
        Task {
            await refreshStats()
        }
    }

    func refreshStats() async {
        let highCache = await manager.cacheSizeHigh()
        let lowCache = await manager.cacheSizeLow()
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        await MainActor.run {
            cacheCount = highCache + lowCache
            storageSizeString = String(format: "%.1f MB", mb)
            
            activeDownloads = manager.activeDownloadsCount()
        }
    }

    func clearCache() {
        manager.clearAllCache()
        Task {
            await refreshStats()
        }
    }

    func clearStorage() {
        manager.clearStorage { [weak self] _ in
            Task {
                await self?.refreshStats()
            }
        }
    }

    func clearAll() {
        manager.hardReset()
        Task {
            await refreshStats()
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshStats()
            }
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
