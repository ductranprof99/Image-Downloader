//
//  StorageImageView.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//


import SwiftUI
import ImageDownloader

struct StorageImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else if isLoading {
                Color.gray.opacity(0.2)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        ProgressView()
                    )
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo.slash")
                            .foregroundColor(.gray)
                    )
            }
        }
        .task {
            await loadFromStorageOnly()
        }
    }

    private func loadFromStorageOnly() async {
        // Load from storage only - use the public API
        // Note: This will still try cache first, then storage
        // For true storage-only, you'd need a custom implementation
        do {
            let result = try await ImageDownloaderManager.shared.requestImageAsync(
                at: url,
                priority: .low,
                shouldSaveToStorage: false  // Don't save, just load
            )

            // Only use if it came from cache/storage (not network)
            if result.fromCache || result.fromStorage {
                await MainActor.run {
                    self.image = result.image
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
