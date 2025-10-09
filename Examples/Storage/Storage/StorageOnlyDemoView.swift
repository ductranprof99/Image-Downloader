//
//  StorageOnlyDemoView.swift
//  Storage
//
//  Created by ductd on 9/10/25.
//

import SwiftUI
import ImageDownloader

struct StorageOnlyDemoView: View {

    @StateObject private var viewModel = StorageOnlyViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Storage Mode Picker
                Picker("Storage Mode", selection: $viewModel.storageMode) {
                    ForEach(StorageMode.allCases, id: \.self) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storage-Only Demo")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.storageMode.message)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    // Stats
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Stored Images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.storedImageCountString)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Storage Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.totalBytesCountString)
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
                        ForEach(viewModel.storedImagesDynamic, id: \.self) { url in
                            StorageImageView(
                                url: url,
                                mode: $viewModel.storageMode,
                                totalBytesCount: $viewModel.totalBytesCount,
                                storageItemImageCount: $viewModel.storedImageCount,
                                downloadTask: $viewModel.downloadTask
                            )
                        }
                    }
                    // Changing this ID after cache clear forces full subtree rebuild
                    .id(viewModel.refreshKey)
                    .padding()
                }

                if viewModel.storedImagesDynamic.isEmpty {
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
                        viewModel.refreshCache()
                    }) {
                        Label("Reload", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        viewModel.clearTempCache()
                    }) {
                        Label("Clear Temp Cache", systemImage: "memorychip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

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
        .task {
            viewModel.reloadData()
        }
    }
}


// MARK: - Preview
#Preview {
    StorageOnlyDemoView()
}
