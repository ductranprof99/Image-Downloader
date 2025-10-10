//
//  NetworkCustomViewModel.swift
//  NetworkDownloader
//
//  Created by ductd on 9/10/25.
//


import SwiftUI
import ImageDownloader

final class NetworkCustomViewModel: ObservableObject {
    // MARK: - Second Tab
    // Network config
    @Published var maxConcurrent: Int = 4
    @Published var timeout: TimeInterval = 30
    @Published var allowsCellular: Bool = true
    
    // MARK: - First Tab
    // Retry config
    @Published var maxRetries: Int = 3
    @Published var baseDelay: TimeInterval = 1.0
    @Published var enableRetryLogging: Bool = false

    // Headers
    @Published var addUserAgent: Bool = false
    @Published var addAPIKey: Bool = false
    @Published var activeHeaders: [(key: String, value: String)] = []

    // Test state
    @Published var currentTestURL: String = "https://picsum.photos/400/600"
    @Published var isLoading: Bool = false
    
    @Published var progress: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var downloadBytes: Double = 0.0
    
    @Published var loadedImage: UIImage?
    @Published var loadError: String?
    @Published var loadStats: LoadStats?

    private var customConfig: IDConfiguration?
    private var loadStartTime: Date?
}


// MARK: - First Tab
extension NetworkCustomViewModel {
    func updateNetworkConfig() {
        // Build custom headers
        var headers: [String: String]? = nil
        if addUserAgent || addAPIKey {
            headers = [:]
            if addUserAgent {
                headers?["User-Agent"] = "ImageDownloader-Demo/1.0"
            }
            if addAPIKey {
                headers?["X-API-Key"] = "demo-key-12345"
            }

            activeHeaders = headers?.map { (key: $0.key, value: $0.value) } ?? []
        } else {
            activeHeaders = []
        }

        // Create retry policy
        let retryPolicy = IDRetryPolicy(
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            backoffMultiplier: 2.0,
            maxDelay: 60.0
        )

        // Build config using ConfigBuilder
        customConfig = ConfigBuilder()
            .maxConcurrentDownloads(maxConcurrent)
            .timeout(timeout)
            .allowsCellularAccess(allowsCellular)
            .retryPolicy(retryPolicy)
            .customHeaders(headers)
            .enableDebugLogging(enableRetryLogging)
            .build()
    }

    func loadSingleTestImage() {
        guard let url = URL(string: currentTestURL) else {
            loadError = "Invalid URL"
            return
        }
        
        isLoading = true
        progress = 0.0
        loadedImage = nil
        loadError = nil
        loadStats = nil
        loadStartTime = Date()
        
        updateNetworkConfig()
        
        let manager = ImageDownloaderManager.instance(for: customConfig)

        manager.requestImage(
            at: url,
            caller: self,
            progress: { [weak self] progress, speed, bytes in
                Task { @MainActor in
                    self?.progress = Double(progress)
                    self?.speed = Double(speed)
                    self?.downloadBytes = Double(bytes)
                }
            },
            completion: { [weak self] image, error, fromCache, fromStorage in
                Task { @MainActor in
                    guard let self = self else { return }

                    self.isLoading = false

                    if let image = image {
                        self.loadedImage = image

                        let loadTime = Date().timeIntervalSince(self.loadStartTime ?? Date())
                        let source = fromCache ? "Cache" : (fromStorage ? "Storage" : "Network")

                        self.loadStats = LoadStats(
                            loadTime: loadTime,
                            speed: self.speed,
                            size: self.downloadBytes,
                            source: source,
                            retryCount: 0
                        )
                    } else if let error = error {
                        self.loadError = error.localizedDescription
                    }
                }
            }
        )
    }
}


