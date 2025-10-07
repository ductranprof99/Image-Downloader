//
//  StorageControlDemoView.swift
//  ImageDownloader
//
//  Demo showing storage control: file explorer, folder structures, compression
//

import SwiftUI
import ImageDownloader

struct StorageControlDemoView: View {

    @StateObject private var viewModel = StorageControlViewModel()
    @State private var selectedCompression: CompressionType = .png
    @State private var selectedPathProvider: PathProviderType = .flat
    @State private var jpegQuality: Double = 0.8

    var body: some View {
        NavigationView {
            List {
                // Compression Settings
                Section {
                    Picker("Compression Format", selection: $selectedCompression) {
                        Text("PNG (Lossless)").tag(CompressionType.png)
                        Text("JPEG").tag(CompressionType.jpeg)
                        Text("Adaptive").tag(CompressionType.adaptive)
                    }
                    .onChange(of: selectedCompression) {
                        viewModel.updateCompression(selectedCompression, quality: jpegQuality)
                    }

                    if selectedCompression == .jpeg || selectedCompression == .adaptive {
                        VStack(alignment: .leading) {
                            Text("JPEG Quality: \(Int(jpegQuality * 100))%")
                                .font(.caption)
                            Slider(value: $jpegQuality, in: 0.1...1.0, step: 0.1)
                                .onChange(of: jpegQuality) {
                                    viewModel.updateCompression(selectedCompression, quality: jpegQuality)
                                }
                        }
                    }

                    Text("Current: \(viewModel.compressionInfo)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                } header: {
                    Text("Compression Algorithm")
                } footer: {
                    Text("PNG is lossless but uses more space. JPEG saves 70% space. Adaptive chooses based on image size.")
                }

                // Folder Structure Settings
                Section {
                    Picker("Folder Structure", selection: $selectedPathProvider) {
                        Text("Flat (All in one folder)").tag(PathProviderType.flat)
                        Text("By Domain").tag(PathProviderType.domain)
                        Text("By Date").tag(PathProviderType.date)
                    }
                    .onChange(of: selectedPathProvider) {
                        viewModel.updatePathProvider(selectedPathProvider)
                    }

                    Text("Current: \(viewModel.pathProviderInfo)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Example path
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example path:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.examplePath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                } header: {
                    Text("Folder Structure")
                } footer: {
                    Text("Flat: All files in root. Domain: Organized by website. Date: Organized by download date.")
                }

                // Storage Statistics
                Section {
                    HStack {
                        Text("Total Size")
                        Spacer()
                        Text(viewModel.storageSizeString)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("File Count")
                        Spacer()
                        Text("\(viewModel.fileCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Storage Path")
                        Spacer()
                        Text(viewModel.storagePathShort)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                } header: {
                    Text("Storage Statistics")
                }

                // File Browser
                Section {
                    NavigationLink {
                        FileExplorerView(viewModel: viewModel)
                    } label: {
                        Label("Browse Files", systemImage: "folder")
                    }

                    Button(action: {
                        viewModel.refreshStats()
                    }) {
                        Label("Refresh Stats", systemImage: "arrow.clockwise")
                    }

                } header: {
                    Text("File Management")
                }

                // Actions
                Section {
                    Button(role: .destructive, action: {
                        viewModel.clearAllStorage()
                    }) {
                        Label("Clear All Storage", systemImage: "trash")
                    }

                } header: {
                    Text("Actions")
                }
            }
            .navigationTitle("Storage Control")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.loadInfo()
        }
    }
}




// MARK: - Preview
#Preview {
    StorageControlDemoView()
}

