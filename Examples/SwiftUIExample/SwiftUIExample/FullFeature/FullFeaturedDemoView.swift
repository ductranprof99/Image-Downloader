//
//  FullFeaturedDemoView.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import SwiftUI
import ImageDownloader

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
                                config: IDConfiguration.highPerformance,
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
