//
//  ImageDecoder.swift
//  ImageDownloader
//
//  Handles image decoding from raw data
//  Separate from networking to maintain single responsibility
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Image decoder that converts raw data to UIImage
/// Handles decoding on background thread for performance
final class ImageDecoder: NSObject {
    
    // MARK: - ObjC Compatible API
    
    /// Decode image data synchronously (ObjC compatible)
    @objc static func decodeImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    /// Decode image data asynchronously (ObjC compatible)
    @objc static func decodeImageAsync(
        from data: Data,
        completion: @escaping (UIImage?) -> Void
    ) {
        Task {
            let image = await decode(from: data)
            await MainActor.run {
                completion(image)
            }
        }
    }
    
    // MARK: - Swift Modern API
    
    /// Decode image data asynchronously with async/await
    static func decode(from data: Data) async -> UIImage? {
        // Perform decoding on background thread
        return await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
    }
    
    /// Decode image data asynchronously with error handling
    static func decodeOrThrow(from data: Data) async throws -> UIImage {
        guard let image = await decode(from: data) else {
            throw ImageDownloaderError.decodingFailed
        }
        return image
    }
    
    // MARK: - Advanced Decoding Options
    
    /// Decode with specific scale factor
    static func decode(
        from data: Data,
        scale: CGFloat
    ) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            UIImage(data: data, scale: scale)
        }.value
    }
    
    /// Pre-decode and draw image for faster rendering
    /// This forces the image to be decoded immediately
    static func preDecodedImage(from data: Data) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data) else { return nil }
            
            // Force decode by drawing into context
            let imageRef = image.cgImage
            guard let cgImage = imageRef else { return image }
            
            let width = cgImage.width
            let height = cgImage.height
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            ) else {
                return image
            }
            
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.draw(cgImage, in: rect)
            
            guard let decodedImageRef = context.makeImage() else {
                return image
            }
            
            return UIImage(cgImage: decodedImageRef, scale: image.scale, orientation: image.imageOrientation)
        }.value
    }
}
