//
//  ProgressiveAsyncImage.swift
//  ImageDownloader
//
//  Created by ductd on 9/10/25.
//

import SwiftUI

/// SwiftUI view using ImageLoader for progress tracking
/// Features:
/// - Automatic cancellation on disappear
/// - URL change detection with automatic cancel/reload
/// - Progress tracking
@available(iOS 15.0, macOS 10.15, *)
public struct ProgressiveAsyncImage<Content: View, Placeholder: View>: View {

    @StateObject private var loader = ImageLoader()

    private let url: URL
    private let config: IDConfiguration?
    private let priority: DownloadPriority
    private let content: (Image, CGFloat) -> Content
    private let placeholder: () -> Placeholder

    public init(
        url: URL,
        config: IDConfiguration? = nil,
        priority: DownloadPriority = .high,
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
        .onChange(of: url) { newURL in
            loader.load(from: newURL, config: config, priority: priority)
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
        config: IDConfiguration? = nil,
        priority: DownloadPriority = .high
    ) {
        self.url = url
        self.config = config
        self.priority = priority
        self.content = { image, _ in image.resizable() }
        self.placeholder = { Color.gray.opacity(0.2) }
    }
}
