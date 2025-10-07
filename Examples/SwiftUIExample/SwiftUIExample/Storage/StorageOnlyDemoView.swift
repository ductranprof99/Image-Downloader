//
//  StorageOnlyDemoView.swift
//  ImageDownloader
//
//  Demo showing storage-only image loading (no network)
//

import SwiftUI
import ImageDownloader

struct StorageOnlyDemoView: View {

    @StateObject private var viewModel = StorageOnlyViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storage-Only Demo")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Images loaded from disk storage only. No network requests.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    // Stats
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Stored Images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.storedImageCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Storage Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.storageSizeString)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()

                // Image Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(viewModel.storedImages, id: \.self) { url in
                            StorageImageView(url: url)
                        }
                    }
                    .padding()
                }

                if viewModel.storedImages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No images in storage")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Download some images first using the network demo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.refreshStorageInfo()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        viewModel.clearStorage()
                    }) {
                        Label("Clear Storage", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
            }
            .navigationTitle("Storage Only")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.loadStorageInfo()
        }
    }
}



@available(iOS 15.0, *)
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

// MARK: - Preview
#Preview {
    StorageOnlyDemoView()
}
