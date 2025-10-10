//
//  ConfigurationView.swift
//  StorageStructure
//
//  Created by ductd on 9/10/25.
//

import SwiftUI
import ImageDownloader

struct ConfigurationView: View {
    @ObservedObject var viewModel: StorageViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Identifier Provider Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Identifier Provider")
                            .font(.headline)

                        VStack(spacing: 12) {
                            ForEach(StorageViewModel.IdentifierType.allCases, id: \.self) { type in
                                HStack {
                                    Text(type.rawValue)
                                        .font(.body)
                                    Spacer()
                                    if viewModel.selectedIdentifier == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedIdentifier = type
                                    viewModel.updateStorageConfig()
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Path Provider Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Path Provider")
                            .font(.headline)

                        VStack(spacing: 12) {
                            ForEach(StorageViewModel.PathType.allCases, id: \.self) { type in
                                HStack {
                                    Text(type.rawValue)
                                        .font(.body)
                                    Spacer()
                                    if viewModel.selectedPath == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedPath = type
                                    viewModel.updateStorageConfig()
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Compression Provider Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Compression Provider")
                            .font(.headline)

                        VStack(spacing: 12) {
                            ForEach(StorageViewModel.CompressionType.allCases, id: \.self) { type in
                                HStack {
                                    Text(type.rawValue)
                                        .font(.body)
                                    Spacer()
                                    if viewModel.selectedCompression == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.orange)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedCompression = type
                                    viewModel.updateStorageConfig()
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Divider()

                    // Buttons Row 1
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.loadMultipleImages()
                        }) {
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Loading...")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Label("Load 4 Images", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)

                        Button(action: {
                            viewModel.clearStorage()
                        }) {
                            Label("Clear", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }

                    // Images Grid
                    if !viewModel.loadedImages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Loaded Images (\(viewModel.loadedImages.count)/\(viewModel.imageURLs.count))")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(viewModel.imageURLs, id: \.self) { urlString in
                                    VStack(spacing: 4) {
                                        if let image = viewModel.loadedImages[urlString] {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 150)
                                                .clipped()
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.green, lineWidth: 2)
                                                )
                                        } else if let progress = viewModel.imageProgress[urlString] {
                                            VStack {
                                                ProgressView(value: progress)
                                                Text("\(Int(progress * 100))%")
                                                    .font(.caption2)
                                            }
                                            .frame(height: 150)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                        }

                                        Text(URL(string: urlString)?.lastPathComponent ?? "")
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }

                    // Error
                    if let error = viewModel.loadError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ConfigurationView(viewModel: StorageViewModel())
}
