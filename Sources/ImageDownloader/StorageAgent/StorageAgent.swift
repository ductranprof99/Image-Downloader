//
//  StorageAgent.swift
//  ImageDownloader
//
//  Disk persistence for downloaded images
//

import Foundation
import UIKit
import CryptoKit

public class StorageAgent {

    // MARK: - Properties

    public var diskCacheSizeLimit: UInt = 0 // bytes (0 = unlimited)

    private let fileManager: FileManager
    private let storageURL: URL
    private let ioQueue = DispatchQueue(label: "com.imagedownloader.storageagent.io")

    // Customization providers
    private let identifierProvider: ResourceIdentifierProvider
    private let pathProvider: StoragePathProvider
    private let compressionProvider: ImageCompressionProvider

    // MARK: - Initialization

    public init(
        storagePath: String? = nil,
        identifierProvider: ResourceIdentifierProvider? = nil,
        pathProvider: StoragePathProvider? = nil,
        compressionProvider: ImageCompressionProvider? = nil
    ) {
        self.fileManager = FileManager.default

        if let storagePath = storagePath {
            self.storageURL = URL(fileURLWithPath: storagePath)
        } else {
            self.storageURL = Self.defaultStorageDirectory()
        }

        // Use defaults for backward compatibility
        self.identifierProvider = identifierProvider ?? MD5IdentifierProvider()
        self.pathProvider = pathProvider ?? FlatStoragePathProvider()
        self.compressionProvider = compressionProvider ?? PNGCompressionProvider()

        createStorageDirectoryIfNeeded()
    }

    // MARK: - Public Methods (Async/Await)

    /// Check if image exists in storage (synchronous)
    public func hasImage(for url: URL) -> Bool {
        let filePath = self.filePath(for: url)
        return fileManager.fileExists(atPath: filePath)
    }

    /// Load image from storage (async/await)
    @available(iOS 13.0, macOS 10.15, *)
    public func image(for url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            ioQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }

                let filePath = self.filePath(for: url)
                var image: UIImage?

                if self.fileManager.fileExists(atPath: filePath) {
                    if let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                        image = self.compressionProvider.decompress(imageData)
                    }
                }

                continuation.resume(returning: image)
            }
        }
    }

    /// Save image to storage (async/await)
    @available(iOS 13.0, macOS 10.15, *)
    public func saveImage(_ image: UIImage, for url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            ioQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }

                // Create subdirectories if needed
                self.createSubdirectoriesIfNeeded(for: url)

                let filePath = self.filePath(for: url)
                guard let imageData = self.compressionProvider.compress(image) else {
                    continuation.resume(returning: false)
                    return
                }

                let success = (try? imageData.write(to: URL(fileURLWithPath: filePath), options: .atomic)) != nil
                continuation.resume(returning: success)
            }
        }
    }

    // MARK: - Public Methods (Completion Handlers - Objective-C Compatible)

    /// Load image from storage (completion handler)
    @objc public func image(for url: URL, completion: @escaping (UIImage?) -> Void) {
        ioQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let filePath = self.filePath(for: url)
            var image: UIImage?

            if self.fileManager.fileExists(atPath: filePath) {
                if let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                    image = self.compressionProvider.decompress(imageData)
                }
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Save image to storage (completion handler)
    @objc public func saveImage(_ image: UIImage, for url: URL, completion: ((Bool) -> Void)? = nil) {
        ioQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            // Create subdirectories if needed
            self.createSubdirectoriesIfNeeded(for: url)

            let filePath = self.filePath(for: url)
            guard let imageData = self.compressionProvider.compress(image) else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            let success = (try? imageData.write(to: URL(fileURLWithPath: filePath), options: .atomic)) != nil

            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }

    public func removeImage(for url: URL, completion: ((Bool) -> Void)? = nil) {
        ioQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            let filePath = self.filePath(for: url)
            var success = false

            if self.fileManager.fileExists(atPath: filePath) {
                success = (try? self.fileManager.removeItem(atPath: filePath)) != nil
            }

            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }

    public func clearAllStorage(completion: ((Bool) -> Void)? = nil) {
        ioQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            let success = (try? self.fileManager.removeItem(at: self.storageURL)) != nil

            if success {
                self.createStorageDirectoryIfNeeded()
            }

            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }

    public func filePath(for url: URL) -> String {
        let identifier = identifierProvider.identifier(for: url)
        let relativePath = pathProvider.path(for: url, identifier: identifier)
        return storageURL.appendingPathComponent(relativePath).path
    }

    public func currentStorageSize() -> UInt {
        var totalSize: UInt = 0

        ioQueue.sync {
            guard let files = try? fileManager.contentsOfDirectory(atPath: storageURL.path) else {
                return
            }

            for file in files {
                let filePath = storageURL.appendingPathComponent(file).path
                if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                   let fileSize = attributes[.size] as? UInt {
                    totalSize += fileSize
                }
            }
        }

        return totalSize
    }

    // MARK: - Private Methods

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
