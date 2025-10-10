//
//  NetworkRequestViewModel.swift
//  NetworkDownloader
//
//  Created by ductd on 9/10/25.
//

import SwiftUI
import ImageDownloader

final class NetworkRequestViewModel: ObservableObject {
    // Network config
    @Published var maxConcurrent: Int = 4
    @Published var timeout: TimeInterval = 30
    @Published var allowsCellular: Bool = true

    // Loading state
    @Published var isLoading: Bool = false
    @Published var loadedImages: [String: UIImage] = [:]
    @Published var imageProgress: [String: Double] = [:]
    @Published var imageErrors: [String: String] = [:]

    private var customConfig: IDConfiguration?
    private var currentURLs: [String] = []
    private var manager: ImageDownloaderManager?

    func updateNetworkConfig() {
        customConfig = ConfigBuilder()
            .maxConcurrentDownloads(maxConcurrent)
            .enableDebugLogging()
            .disableSaveToStorage()
            .timeout(timeout)
            .allowsCellularAccess(allowsCellular)
            .build()
    }
    
    init() {
        customConfig = ConfigBuilder()
            .maxConcurrentDownloads(maxConcurrent)
            .enableDebugLogging()
            .disableSaveToStorage()
            .timeout(timeout)
            .allowsCellularAccess(allowsCellular)
            .build()
    }

    func loadMultipleImages(urls: [String]) {
        guard !urls.isEmpty else { return }

        isLoading = true
        loadedImages.removeAll()
        imageProgress.removeAll()
        imageErrors.removeAll()
        currentURLs = urls

        updateNetworkConfig()

        let manager = ImageDownloaderManager.instance(for: customConfig)

        for urlString in urls {
            guard let url = URL(string: urlString) else {
                imageErrors[urlString] = "Invalid URL"
                continue
            }

            imageProgress[urlString] = 0.0

            manager.requestImage(
                at: url,
                caller: self,
                progress: { [weak self, urlString] progress, speed, bytes in
                    Task { @MainActor in
                        self?.imageProgress[urlString] = Double(progress)
                    }
                },
                completion: { [weak self, urlString] image, error, fromCache, fromStorage in
                    Task { @MainActor in
                        guard let self = self else { return }

                        if let image = image {
                            self.loadedImages[urlString] = image
                            self.imageProgress[urlString] = 1.0
                        } else if let error = error {
                            self.imageErrors[urlString] = error.localizedDescription
                        }

                        // Check if all images are done
                        let totalImages = urls.count
                        let completedImages = self.loadedImages.count + self.imageErrors.count
                        if completedImages >= totalImages {
                            self.isLoading = false
                        }
                    }
                }
            )
        }
        self.manager = manager
    }

    func resetAll() {
        // Cancel all ongoing requests
        if manager != nil {
            manager?.hardReset()
        }
        
        let manager = ImageDownloaderManager.instance(for: customConfig)
        for urlString in currentURLs {
            if let url = URL(string: urlString) {
                manager.cancelAllRequests(for: url)
            }
        }

        // Reset state
        isLoading = false
        loadedImages.removeAll()
        imageProgress.removeAll()
        imageErrors.removeAll()
        currentURLs.removeAll()
    }
}
