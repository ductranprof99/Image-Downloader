//
//  FullFeaturedDemoView.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import SwiftUI

struct FullFeaturedDemoView: View {
    @StateObject private var viewModel = FullFeaturedViewModel()

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats bar
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Cache")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.cacheCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    VStack(spacing: 4) {
                        Text("Storage")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(viewModel.storageSizeString)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    VStack(spacing: 4) {
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.activeDownloads)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.imageItems, id: \.id) { item in
                            AsyncImageView(
                                url: item.url,
                                config: FastConfig.shared,
                                placeholder: Image(systemName: "photo"),
                                errorImage: Image(systemName: "exclamationmark.triangle"),
                                priority: .high
                            )
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Full Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.clearCache()
                        }) {
                            Label("Clear Cache", systemImage: "memorychip")
                        }

                        Button(action: {
                            viewModel.clearStorage()
                        }) {
                            Label("Clear Storage", systemImage: "internaldrive")
                        }

                        Button(role: .destructive, action: {
                            viewModel.clearAll()
                        }) {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.refreshStats()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadImages()
        }
    }
}

@available(iOS 15.0, *)
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
        refreshStats()
    }

    func refreshStats() {
        let highCache = manager.cacheSizeHigh()
        let lowCache = manager.cacheSizeLow()
        cacheCount = highCache + lowCache

        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        storageSizeString = String(format: "%.1f MB", mb)

        activeDownloads = manager.activeDownloadsCount()
    }

    func clearCache() {
        manager.clearAllCache()
        refreshStats()
    }

    func clearStorage() {
        manager.clearStorage { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshStats()
            }
        }
    }

    func clearAll() {
        manager.hardReset()
        refreshStats()
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshStats()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
