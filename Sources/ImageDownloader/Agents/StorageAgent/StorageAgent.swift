//
//  StorageAgent.swift
//  ImageDownloader
//
//  Disk persistence for downloaded images
//

import Foundation
import UIKit

// MARK: - Private + Init
final class StorageAgent {
    
    private var diskCacheSizeLimit: UInt = 0 // bytes (0 = unlimited)
    private let fileManager: FileManager
    private let storageURL: URL
    
    // Customization providers
    private let identifierProvider: ResourceIdentifierProvider
    private let pathProvider: StoragePathProvider
    private let compressionProvider: ImageCompressionProvider
    
    // MARK: - Initialization
    init(
        config: StorageConfig
    ) {
        self.fileManager = FileManager.default
        
        if let storagePath = config.storagePath {
            self.storageURL = URL(fileURLWithPath: storagePath)
        } else {
            self.storageURL = Self.defaultStorageDirectory()
        }
        
        // Use defaults for backward compatibility
        self.identifierProvider = config.identifierProvider
        self.pathProvider = config.pathProvider
        self.compressionProvider = config.compressionProvider
        
        createStorageDirectoryIfNeeded()
    }
    
    
    
    private static func defaultStorageDirectory() -> URL {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachePath = paths.first!
        return URL(fileURLWithPath: cachePath).appendingPathComponent("ImageDownloaderStorage")
    }
    
    private func createStorageDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: storageURL.path) {
            try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
        }
    }
    
    private func createSubdirectoriesIfNeeded(for url: URL) {
        let subdirectories = pathProvider.directoryStructure(for: url)
        guard !subdirectories.isEmpty else { return }
        
        var directoryURL = storageURL
        for subdirectory in subdirectories {
            directoryURL = directoryURL.appendingPathComponent(subdirectory)
        }
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}


// MARK: - Expose to manager
extension StorageAgent {
    /// Check if image exists in storage (synchronous)
    func hasImage(for url: URL) -> Bool {
        let filePath = self.filePath(for: url)
        return fileManager.fileExists(atPath: filePath)
    }
    
    func image(for url: URL) -> UIImage? {
        let filePath = self.filePath(for: url)
        var image: UIImage? = nil
        
        if self.fileManager.fileExists(atPath: filePath) {
            if let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                image = self.compressionProvider.decompress(imageData)
            }
        }
        
        return image
    }
    
    func saveImage(_ image: UIImage, for url: URL) -> Bool {
        self.createSubdirectoriesIfNeeded(for: url)
        
        let filePath = self.filePath(for: url)
        guard let imageData = self.compressionProvider.compress(image) else {
            return false
        }
        
        return (try? imageData.write(to: URL(fileURLWithPath: filePath), options: .atomic)) != nil
    }
    
    func removeImage(for url: URL) -> Bool {
        let filePath = self.filePath(for: url)
        var success = false
        
        if self.fileManager.fileExists(atPath: filePath) {
            success = (try? self.fileManager.removeItem(atPath: filePath)) != nil
        }
        return success
    }
    
    
    
    func filePath(for url: URL) -> String {
        let identifier = identifierProvider.identifier(for: url)
        let relativePath = pathProvider.path(for: url, identifier: identifier)
        return storageURL.appendingPathComponent(relativePath).path
    }
    
    func currentStorageSize() -> UInt {
        var totalSize: UInt = 0
        
        guard let files = try? fileManager.contentsOfDirectory(atPath: storageURL.path) else {
            return totalSize
        }
        
        for file in files {
            let filePath = storageURL.appendingPathComponent(file).path
            if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
               let fileSize = attributes[.size] as? UInt {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    func fileCount() -> Int {
        let a = try? fileManager.contentsOfDirectory(atPath: storageURL.path).count
        return a ?? 0
    }
    
    func removeAll() {
        do {
            try fileManager.removeItem(at: storageURL)
        } catch {
            print("Error removing all files from storage: \(error)")
        }
    }
}

