//
//  StorageControlDemoView.swift
//  ImageDownloader
//
//  Demo showing storage control: file explorer, folder structures, compression
//

import SwiftUI
import ImageDownloader

@available(iOS 15.0, *)
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
                    .onChange(of: selectedCompression) { _ in
                        viewModel.updateCompression(selectedCompression, quality: jpegQuality)
                    }

                    if selectedCompression == .jpeg || selectedCompression == .adaptive {
                        VStack(alignment: .leading) {
                            Text("JPEG Quality: \(Int(jpegQuality * 100))%")
                                .font(.caption)
                            Slider(value: $jpegQuality, in: 0.1...1.0, step: 0.1)
                                .onChange(of: jpegQuality) { _ in
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
                    .onChange(of: selectedPathProvider) { _ in
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

@available(iOS 15.0, *)
class StorageControlViewModel: ObservableObject {
    @Published var compressionInfo: String = "PNG"
    @Published var pathProviderInfo: String = "Flat"
    @Published var examplePath: String = ""
    @Published var storageSizeString: String = "0 MB"
    @Published var fileCount: Int = 0
    @Published var storagePathShort: String = ""
    @Published var fileList: [StorageFileInfo] = []

    private let manager = ImageDownloaderManager.shared
    private var currentCompressionProvider: ImageCompressionProvider = PNGCompressionProvider()
    private var currentPathProvider: StoragePathProvider = FlatStoragePathProvider()

    func loadInfo() {
        updateCompressionInfo()
        updatePathProviderInfo()
        updateExamplePath()
        refreshStats()
    }

    func updateCompression(_ type: CompressionType, quality: Double) {
        switch type {
        case .png:
            currentCompressionProvider = PNGCompressionProvider()
        case .jpeg:
            currentCompressionProvider = JPEGCompressionProvider(quality: quality)
        case .adaptive:
            currentCompressionProvider = AdaptiveCompressionProvider(sizeThresholdMB: 1.0, jpegQuality: quality)
        }
        updateCompressionInfo()
        updateExamplePath()
    }

    func updatePathProvider(_ type: PathProviderType) {
        switch type {
        case .flat:
            currentPathProvider = FlatStoragePathProvider()
        case .domain:
            currentPathProvider = DomainHierarchicalPathProvider()
        case .date:
            currentPathProvider = DateHierarchicalPathProvider()
        }
        updatePathProviderInfo()
        updateExamplePath()
    }

    func refreshStats() {
        let bytes = manager.storageSizeBytes()
        let mb = Double(bytes) / 1_048_576
        storageSizeString = String(format: "%.2f MB", mb)

        // Get storage path
        let storageAgent = manager.storageAgent
        let exampleURL = URL(string: "https://example.com/image.jpg")!
        let fullPath = storageAgent.filePath(for: exampleURL)
        storagePathShort = (fullPath as NSString).lastPathComponent

        // Count files (simplified)
        if let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let storageURL = cachesDir.appendingPathComponent("ImageDownloaderStorage")
            if let files = try? FileManager.default.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil) {
                fileCount = files.count

                // Get file list with info
                fileList = files.compactMap { url in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let size = attributes[.size] as? UInt64,
                          let modificationDate = attributes[.modificationDate] as? Date else {
                        return nil
                    }
                    return StorageFileInfo(
                        name: url.lastPathComponent,
                        path: url.path,
                        size: size,
                        modificationDate: modificationDate
                    )
                }
                .sorted { $0.modificationDate > $1.modificationDate }
            } else {
                fileCount = 0
                fileList = []
            }
        }
    }

    func clearAllStorage() {
        manager.clearStorage { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.refreshStats()
                }
            }
        }
    }

    private func updateCompressionInfo() {
        compressionInfo = currentCompressionProvider.name
    }

    private func updatePathProviderInfo() {
        switch currentPathProvider {
        case is FlatStoragePathProvider:
            pathProviderInfo = "Flat"
        case is DomainHierarchicalPathProvider:
            pathProviderInfo = "Domain Hierarchical"
        case is DateHierarchicalPathProvider:
            pathProviderInfo = "Date Hierarchical"
        default:
            pathProviderInfo = "Custom"
        }
    }

    private func updateExamplePath() {
        let exampleURL = URL(string: "https://picsum.photos/id/237/200/300.jpg")!
        let identifier = MD5IdentifierProvider().identifier(for: exampleURL)
        let path = currentPathProvider.path(for: exampleURL, identifier: identifier)
        examplePath = path
    }
}

enum CompressionType {
    case png
    case jpeg
    case adaptive
}

enum PathProviderType {
    case flat
    case domain
    case date
}

struct StorageFileInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: UInt64
    let modificationDate: Date

    var sizeString: String {
        let kb = Double(size) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024
            return String(format: "%.2f MB", mb)
        }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
}

@available(iOS 15.0, *)
struct FileExplorerView: View {
    @ObservedObject var viewModel: StorageControlViewModel

    var body: some View {
        List {
            if viewModel.fileList.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No files in storage")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(viewModel.fileList) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack {
                            Text(file.sizeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(file.dateString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("File Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshStats()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.refreshStats()
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct StorageControlDemoView_Previews: PreviewProvider {
    static var previews: some View {
        StorageControlDemoView()
    }
}
