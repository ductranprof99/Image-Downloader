//
//  StorageViewModel.swift
//  StorageStructure
//
//  Created by ductd on 9/10/25.
//

import SwiftUI
import ImageDownloader

final class StorageViewModel: ObservableObject {
    // Storage providers selection
    @Published var selectedIdentifier: IdentifierType = .md5
    @Published var selectedPath: PathType = .flat
    @Published var selectedCompression: CompressionType = .png

    // Test state
    @Published var isLoading: Bool = false
    @Published var loadedImages: [String: UIImage] = [:]
    @Published var imageProgress: [String: Double] = [:]
    @Published var loadError: String?

    // Storage info
    @Published var storageInfo: StorageInfo?
    @Published var folderStructure: [FolderNode] = []

    private var customConfig: IDConfiguration?

    let imageURLs = [
        "https://picsum.photos/id/299/4000/4000",
        "https://picsum.photos/id/871/4000/4000",
        "https://picsum.photos/id/904/4000/4000",
        "https://picsum.photos/id/680/4000/4000",
        "https://picsum.photos/id/579/4000/4000",
        "https://picsum.photos/id/460/4000/4000",
        "https://picsum.photos/id/737/4000/4000",
        "https://picsum.photos/id/181/4000/4000",
        "https://picsum.photos/id/529/4000/4000",
        "https://picsum.photos/id/94/4000/4000",
        "https://picsum.photos/id/500/4000/4000",
        "https://picsum.photos/id/423/4000/4000",
        "https://picsum.photos/id/952/4000/4000",
        "https://picsum.photos/id/798/4000/4000",
        "https://picsum.photos/id/151/4000/4000",
        "https://picsum.photos/id/42/4000/4000",
        "https://picsum.photos/id/813/4000/4000",
        "https://picsum.photos/id/187/4000/4000",
        "https://picsum.photos/id/236/4000/4000",
        "https://picsum.photos/id/33/4000/4000"
    ]

    enum IdentifierType: String, CaseIterable {
        case md5 = "MD5"
        case sha256 = "SHA256"

        var provider: ResourceIdentifierProvider {
            switch self {
            case .md5: return MD5IdentifierProvider()
            case .sha256: return SHA256IdentifierProvider()
            }
        }
    }

    enum PathType: String, CaseIterable {
        case flat = "Flat"
        case domain = "Domain"
        case date = "Date"

        var provider: StoragePathProvider {
            switch self {
            case .flat: return FlatHierarchicalPathProvider()
            case .domain: return DomainHierarchicalPathProvider()
            case .date: return DateHierarchicalPathProvider()
            }
        }
    }

    enum CompressionType: String, CaseIterable {
        case png = "PNG"
        case jpeg80 = "JPEG 80%"
        case jpeg50 = "JPEG 50%"
        case adaptive = "Adaptive"

        var provider: ImageCompressionProvider {
            switch self {
            case .png: return PNGCompressionProvider()
            case .jpeg80: return JPEGCompressionProvider(quality: 0.8)
            case .jpeg50: return JPEGCompressionProvider(quality: 0.5)
            case .adaptive: return AdaptiveCompressionProvider()
            }
        }
    }

    func updateStorageConfig() {
        customConfig = ConfigBuilder()
            .enableSaveToStorage()
            .identifierProvider(selectedIdentifier.provider)
            .pathProvider(selectedPath.provider)
            .compressionProvider(selectedCompression.provider)
            .build()

        updateStorageInfo()
    }

    func updateStorageInfo() {
        let manager = ImageDownloaderManager.instance(for: customConfig)

        // Get storage stats
        let size = manager.storageSizeBytes()
        let count = manager.storedImageCount()

        storageInfo = StorageInfo(
            totalSize: size,
            fileCount: count
        )

        // Build folder structure
        buildFolderStructure()
    }

    func buildFolderStructure() {
        var structure: [String: [String]] = [:]

        for urlString in imageURLs {
            guard let url = URL(string: urlString) else { continue }

            let identifier = selectedIdentifier.provider.identifier(for: url)
            let relativePath = selectedPath.provider.path(for: url, identifier: identifier)
            let directories = selectedPath.provider.directoryStructure(for: url)

            if directories.isEmpty {
                // Flat structure
                structure["root", default: []].append(relativePath)
            } else {
                // Hierarchical structure
                let folder = directories.joined(separator: "/")
                structure[folder, default: []].append(relativePath.components(separatedBy: "/").last ?? relativePath)
            }
        }

        // Convert to FolderNode array
        folderStructure = structure.map { key, files in
            FolderNode(name: key, files: files)
        }.sorted { $0.name < $1.name }
    }

    func loadMultipleImages() {
        isLoading = true
        loadedImages.removeAll()
        imageProgress.removeAll()
        loadError = nil

        updateStorageConfig()

        let manager = ImageDownloaderManager.instance(for: customConfig)

        for urlString in imageURLs {
            guard let url = URL(string: urlString) else { continue }

            imageProgress[urlString] = 0.0

            manager.requestImage(
                at: url,
                caller: self,
                progress: { [weak self] progress, speed, bytes in
                    Task { @MainActor in
                        self?.imageProgress[urlString] = Double(progress)
                    }
                },
                completion: { [weak self] image, error, fromCache, fromStorage in
                    Task { @MainActor in
                        if let image = image {
                            self?.loadedImages[urlString] = image
                            self?.imageProgress[urlString] = 1.0
                        }

                        // Check if all done
                        if let self = self {
                            let totalImages = self.imageURLs.count
                            let completedImages = self.loadedImages.count
                            if completedImages >= totalImages {
                                self.isLoading = false
                                self.updateStorageInfo()
                            }
                        }
                    }
                }
            )
        }
    }

    func clearStorage() {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        manager.clearStorage()
        loadedImages.removeAll()
        imageProgress.removeAll()
        updateStorageInfo()
    }
}

struct StorageInfo {
    let totalSize: UInt
    let fileCount: Int

    var sizeString: String {
        let mb = Double(totalSize) / (1024 * 1024)
        if mb < 0.01 {
            return "\(totalSize) bytes"
        }
        return String(format: "%.2f MB", mb)
    }
}

struct FolderNode: Identifiable {
    let id = UUID()
    let name: String
    let files: [String]
}
