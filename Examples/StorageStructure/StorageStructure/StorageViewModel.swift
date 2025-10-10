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
    private var manager: ImageDownloaderManager?

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
        case customDomain = "Custom Domain"
        case customDateTime = "Custom Date/Time"
        case customIDRange = "ID Range (low/mid/high)"

        var provider: StoragePathProvider {
            switch self {
            case .flat: return FlatHierarchicalPathProvider()
            case .customDomain: return CustomDomainPathProvider()
            case .customDateTime: return CustomDateTimePathProvider()
            case .customIDRange: return CustomIDRangePathProvider()
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
        // Clear old storage structure with old files
        if self.manager != nil {
            self.manager?.clearStorage()
        }

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
        self.manager = manager
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

            print("📁 URL: \(urlString)")
            print("📁 Identifier: \(identifier)")
            print("📁 Relative path: \(relativePath)")
            print("📁 Directories: \(directories)")

            if directories.isEmpty {
                // Flat structure
                structure["root", default: []].append(relativePath)
            } else {
                // Hierarchical structure
                let folder = directories.joined(separator: "/")
                structure[folder, default: []].append(relativePath.components(separatedBy: "/").last ?? relativePath)
            }
        }

        print("📁 Final structure: \(structure)")

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
                progress: { [weak self, urlString] progress, speed, bytes in
                    Task { @MainActor in
                        self?.imageProgress[urlString] = Double(progress)
                    }
                },
                completion: { [weak self, urlString] image, error, fromCache, fromStorage in
                    Task { @MainActor in
                        guard let self = self else { return }

                        if let image = image {
                            self.loadedImages[urlString] = image
                            self.imageProgress[urlString] = 1.0
                        }

                        // Check if all done
                        let totalImages = self.imageURLs.count
                        let completedImages = self.loadedImages.count
                        if completedImages >= totalImages {
                            self.isLoading = false
                            self.updateStorageInfo()
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

    func openStorageFolder() {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        let storagePath = manager.storagePath()

        #if os(macOS)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: storagePath)
        #else
        // For iOS simulator, print path to console
        print("Storage folder path: \(storagePath)")
        // You can also copy to pasteboard
        UIPasteboard.general.string = storagePath
        #endif
    }

    func getStoragePath() -> String {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        return manager.storagePath()
    }

    func getStorageURL() -> URL {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        return manager.storagePathURL()
    }

    func listFiles(at path: String? = nil) -> [FileItem] {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        let baseURL = manager.storagePathURL()

        let directoryURL = path.map { baseURL.appendingPathComponent($0) } ?? baseURL

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { url -> FileItem? in
            let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            let isDirectory = resourceValues?.isDirectory ?? false
            let fileSize = resourceValues?.fileSize ?? 0

            let relativePath = path.map { "\($0)/\(url.lastPathComponent)" } ?? url.lastPathComponent

            return FileItem(
                name: url.lastPathComponent,
                relativePath: relativePath,
                isDirectory: isDirectory,
                size: fileSize,
                url: url
            )
        }.sorted { item1, item2 in
            // Folders first, then alphabetically
            if item1.isDirectory != item2.isDirectory {
                return item1.isDirectory
            }
            return item1.name < item2.name
        }
    }

    func buildFileTree() -> [TreeNode] {
        let manager = ImageDownloaderManager.instance(for: customConfig)
        let baseURL = manager.storagePathURL()
        return buildTreeRecursive(at: baseURL, relativePath: nil)
    }

    private func buildTreeRecursive(at url: URL, relativePath: String?) -> [TreeNode] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { itemURL -> TreeNode? in
            let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            let isDirectory = resourceValues?.isDirectory ?? false
            let fileSize = resourceValues?.fileSize ?? 0
            let name = itemURL.lastPathComponent
            let itemRelativePath = relativePath.map { "\($0)/\(name)" } ?? name

            var children: [TreeNode] = []
            if isDirectory {
                children = buildTreeRecursive(at: itemURL, relativePath: itemRelativePath)
            }

            return TreeNode(
                name: name,
                relativePath: itemRelativePath,
                isDirectory: isDirectory,
                size: fileSize,
                url: itemURL,
                children: children
            )
        }.sorted { node1, node2 in
            if node1.isDirectory != node2.isDirectory {
                return node1.isDirectory
            }
            return node1.name < node2.name
        }
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

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let relativePath: String
    let isDirectory: Bool
    let size: Int
    let url: URL

    var sizeString: String {
        let kb = Double(size) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }
}

struct TreeNode: Identifiable {
    let id = UUID()
    let name: String
    let relativePath: String
    let isDirectory: Bool
    let size: Int
    let url: URL
    let children: [TreeNode]

    var sizeString: String {
        let kb = Double(size) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024
        return String(format: "%.2f MB", mb)
    }
}
