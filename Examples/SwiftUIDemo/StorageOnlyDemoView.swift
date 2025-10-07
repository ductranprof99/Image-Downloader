//
//  StorageOnlyDemoView.swift
//  ImageDownloader
//
//  Demo showing storage-only image loading (no network)
//

import SwiftUI
import ImageDownloader

@available(iOS 15.0, *)
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
class StorageOnlyViewModel: ObservableObject {
    @Published var storedImages: [URL] = []
    @Published var storedImageCount: Int = 0
    @Published var storageSizeString: String = "0 MB"

    private let manager = ImageDownloaderManager.shared

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
        // Load from storage only - no network
        let storageAgent = ImageDownloaderManager.shared.storageAgent

        if let storedImage = await storageAgent.image(for: url) {
            await MainActor.run {
                self.image = storedImage
                self.isLoading = false
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct StorageOnlyDemoView_Previews: PreviewProvider {
    static var previews: some View {
        StorageOnlyDemoView()
    }
}
