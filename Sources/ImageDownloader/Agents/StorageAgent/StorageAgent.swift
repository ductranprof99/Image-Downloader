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
    
    private let _fileManager: FileManager
    private let _storageURL: URL
    
    // Customization providers
    private let identifierProvider: ResourceIdentifierProvider
    private let pathProvider: StoragePathProvider
    private let compressionProvider: ImageCompressionProvider
    
    // MARK: - Initialization
    init(
        config: StorageConfig
    ) {
        self._fileManager = FileManager.default
        
        if let storagePath = config.storagePath {
            self._storageURL = URL(fileURLWithPath: storagePath)
        } else {
            self._storageURL = Self.defaultStorageDirectory()
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
        if !_fileManager.fileExists(atPath: _storageURL.path) {
            try? _fileManager.createDirectory(at: _storageURL, withIntermediateDirectories: true)
        }
    }
    
    private func createSubdirectoriesIfNeeded(for url: URL) {
        let subdirectories = pathProvider.directoryStructure(for: url)
        guard !subdirectories.isEmpty else { return }
        
        var directoryURL = _storageURL
        for subdirectory in subdirectories {
            directoryURL = directoryURL.appendingPathComponent(subdirectory)
        }
        
        if !_fileManager.fileExists(atPath: directoryURL.path) {
            try? _fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}


// MARK: - Expose to manager
extension StorageAgent {
    /// Check if image exists in storage (synchronous)
    func hasImage(for url: URL) -> Bool {
        let filePath = self.filePath(for: url)
        return _fileManager.fileExists(atPath: filePath)
    }
    
    func image(for url: URL) -> UIImage? {
        let filePath = self.filePath(for: url)
        var image: UIImage? = nil
        
        if self._fileManager.fileExists(atPath: filePath) {
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
        
        if self._fileManager.fileExists(atPath: filePath) {
            success = (try? self._fileManager.removeItem(atPath: filePath)) != nil
        }
        return success
    }
    
    func filePath(for url: URL) -> String {
        let identifier = identifierProvider.identifier(for: url)
        let relativePath = pathProvider.path(for: url, identifier: identifier)
        return _storageURL.appendingPathComponent(relativePath).path
    }
    
    func storagePath() -> String {
        return _storageURL.path
    }
    
    func storageURL() -> URL {
        return _storageURL
    }
    
    func currentStorageSize() -> UInt {
        var totalSize: UInt = 0
        
        guard let files = try? _fileManager.contentsOfDirectory(atPath: _storageURL.path) else {
            return totalSize
        }
        
        for file in files {
            let filePath = _storageURL.appendingPathComponent(file).path
            if let attributes = try? _fileManager.attributesOfItem(atPath: filePath),
               let fileSize = attributes[.size] as? UInt {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    func fileCount() -> Int {
        let a = try? _fileManager.contentsOfDirectory(atPath: _storageURL.path).count
        return a ?? 0
    }
    
    func removeAll() {
        do {
            try _fileManager.removeItem(at: _storageURL)
        } catch {
            print("Error removing all files from storage: \(error)")
        }
    }
}

