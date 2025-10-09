//
//  AsyncImageView.swift
//  ImageDownloader
//
//  SwiftUI component with built-in progress tracking
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

/// SwiftUI view for loading images with progress tracking
/// Features automatic cancellation on disappear
@available(iOS 15.0, macOS 10.15, *)
public struct AsyncImageView: View {
    
    // MARK: - Properties
    private let url: URL
    private let config: IDConfiguration?
    private let placeholder: Image?
    private let errorImage: Image?
    private let updateLatency: ResourceUpdateLatency
    private let downloadPriority: DownloadPriority
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadProgress: CGFloat = 0.0
    @State private var error: Error?
    @State private var loadingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        url: URL,
        config: IDConfiguration? = nil,
        placeholder: Image? = nil,
        errorImage: Image? = nil,
        updateLatency: ResourceUpdateLatency = .low,
        downloadPriority: DownloadPriority = .low
    ) {
        self.url = url
        self.config = config
        self.placeholder = placeholder
        self.errorImage = errorImage
        self.updateLatency = updateLatency
        self.downloadPriority = downloadPriority
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ZStack {
                    if let placeholder = placeholder {
                        placeholder
                            .resizable()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                    
                    // Progress indicator
                    ProgressView(value: loadProgress, total: 1.0)
                        .progressViewStyle(CircularProgressViewStyle())
                }
            } else if error != nil {
                // Error state
                ZStack {
                    if let errorImage = errorImage {
                        errorImage
                            .resizable()
                    } else {
                        Color.red.opacity(0.1)
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .task(id: url) {
            await loadImage()
        }
        .onDisappear {
            // Cancel loading when view disappears
            cancelLoading()
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadImage() async {
        // Cancel any existing task
        cancelLoading()
        
        isLoading = true
        loadProgress = 0.0
        error = nil
        
        // Create new loading task
        loadingTask = Task {
            do {
                let manager = ImageDownloaderManager.instance(for: config)
                
                let result = try await manager.requestImageAsync(
                    at: url,
                    updateLatency: updateLatency,
                    downloadPriority: downloadPriority
                )
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                loadedImage = result.image
                loadProgress = 1.0
                isLoading = false
                
            } catch is CancellationError {
                // Task was cancelled, do nothing
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
}
#endif
