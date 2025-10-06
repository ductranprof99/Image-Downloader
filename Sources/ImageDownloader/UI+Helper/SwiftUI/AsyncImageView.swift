//
//  AsyncImageView.swift
//  ImageDownloader
//
//  SwiftUI component with built-in progress tracking
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// SwiftUI view for loading images with progress tracking
@available(iOS 15.0, macOS 10.15, *)
public struct AsyncImageView: View {

    // MARK: - Properties

    private let url: URL
    private let config: ImageDownloaderConfigProtocol?
    private let placeholder: Image?
    private let priority: ResourcePriority

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadProgress: CGFloat = 0.0
    @State private var error: Error?

    // MARK: - Initialization

    public init(
        url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        placeholder: Image? = nil,
        priority: ResourcePriority = .low
    ) {
        self.url = url
        self.config = config
        self.placeholder = placeholder
        self.priority = priority
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
                    Color.red.opacity(0.1)
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .task {
            await loadImage()
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadImage() async {
        isLoading = true
        loadProgress = 0.0

        do {
            // Use async/await for cleaner code
            let manager = ImageDownloaderManager.instance(for: config)

            // Create a manual progress tracking task
            let progressTask = Task<Void, Never> {
                // Poll for progress updates
                // Note: This is a workaround until we have async progress APIs
                for _ in 0..<100 {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    // Progress is estimated based on time for now
                    // In a real implementation, we'd get actual progress from the manager
                    if !Task.isCancelled {
                        loadProgress = min(loadProgress + 0.01, 0.9)
                    } else {
                        break
                    }
                }
            }

            // Load the actual image
            let result = try await manager.requestImage(at: url, priority: priority)

            // Cancel progress polling
            progressTask.cancel()

            // Update state
            loadedImage = result.image
            loadProgress = 1.0
            isLoading = false

        } catch {
            self.error = error
            isLoading = false
        }
    }
}

// MARK: - Better SwiftUI Implementation with Observable Progress

/// Observable object for tracking image loading progress
@available(iOS 13.0, macOS 10.15, *)
public class ImageLoader: ObservableObject {

    @Published public var image: UIImage?
    @Published public var isLoading = false
    @Published public var progress: CGFloat = 0.0
    @Published public var error: Error?

    private var url: URL?
    private var config: ImageDownloaderConfigProtocol?

    public init() {}

    @MainActor
    public func load(
        from url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .low
    ) {
        self.url = url
        self.config = config
        self.isLoading = true
        self.progress = 0.0
        self.error = nil

        // Use completion-based API for progress tracking
        let manager = ImageDownloaderManager.instance(for: config)

        manager.requestImage(
            at: url,
            priority: priority,
            progress: { [weak self] progressValue in
                DispatchQueue.main.async {
                    self?.progress = progressValue
                }
            },
            completion: { [weak self] image, error, _, _ in
                DispatchQueue.main.async {
                    self?.image = image
                    self?.error = error
                    self?.isLoading = false
                    self?.progress = 1.0
                }
            },
            caller: self
        )
    }

    public func cancel() {
        guard let url = url else { return }
        let manager = ImageDownloaderManager.instance(for: config)
        manager.cancelRequest(for: url, caller: self)
        isLoading = false
    }
}

/// SwiftUI view using ImageLoader for progress tracking
@available(iOS 15.0, macOS 10.15, *)
public struct ProgressiveAsyncImage<Content: View, Placeholder: View>: View {

    @StateObject private var loader = ImageLoader()

    private let url: URL
    private let config: ImageDownloaderConfigProtocol?
    private let priority: ResourcePriority
    private let content: (Image, CGFloat) -> Content
    private let placeholder: () -> Placeholder

    public init(
        url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .high,
        @ViewBuilder content: @escaping (Image, CGFloat) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.config = config
        self.priority = priority
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image), loader.progress)
            } else {
                placeholder()
                    .overlay(
                        ProgressView(value: loader.progress, total: 1.0)
                            .opacity(loader.isLoading ? 1 : 0)
                    )
            }
        }
        .onAppear {
            loader.load(from: url, config: config, priority: priority)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

// MARK: - Simple API with default placeholder

@available(iOS 15.0, macOS 10.15, *)
extension ProgressiveAsyncImage where Content == Image, Placeholder == Color {

    public init(
        url: URL,
        config: ImageDownloaderConfigProtocol? = nil,
        priority: ResourcePriority = .high
    ) {
        self.url = url
        self.config = config
        self.priority = priority
        self.content = { image, _ in image.resizable() }
        self.placeholder = { Color.gray.opacity(0.2) }
    }
}

#endif
