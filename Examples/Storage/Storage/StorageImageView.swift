//
//  StorageMode.swift
//  Storage
//
//  Created by ductd on 9/10/25.
//

import SwiftUI
import ImageDownloader

struct StorageImageView: View {
    let url: URL
    @Binding var mode: StorageMode
    @Binding var totalBytesCount: Double
    @Binding var storageItemImageCount: Int
    @Binding var downloadTask: Int
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        VStack {
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
                            Image("photo.slash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(20)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        do {
            let result = try await ImageDownloaderManager.shared.requestImageAsync(
                at: url,
                updateLatency: .high,
                downloadPriority: mode.downloadPriority
            )
            let bytes = ImageDownloaderManager.shared.storageSizeBytes()
            let mb = Double(bytes) / 1_048_576
            downloadTask = await ImageDownloaderManager.shared.activeDownloadsCountAsync()
            totalBytesCount = mb
            storageItemImageCount = ImageDownloaderManager.shared.storedImageCount()
            await MainActor.run {
                switch mode {
                case .noStorage:
                    image = result.image
                case .withStorage:
                    image = result.image
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
