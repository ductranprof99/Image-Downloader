//
//  ImageItem.swift
//  UIKitDemo
//
//  Demonstrates ImageDownloader in UIKit
//

import Foundation

struct ImageItem: Identifiable {
    let id: UUID
    let url: URL
    let title: String
    let subtitle: String
    let imageType: ImageType

    enum ImageType {
        case avatar      // Small, fast
        case photo       // Medium, balanced
        case thumbnail   // Tiny, low memory
        case fullSize    // Large, offline-first
    }

    init(id: UUID = UUID(), url: URL, title: String, subtitle: String, imageType: ImageType) {
        self.id = id
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.imageType = imageType
    }
}

// MARK: - Sample Data Generator

extension ImageItem {
    static func generateSampleData(count: Int = 50) -> [ImageItem] {
        var items: [ImageItem] = []

        for i in 0..<count {
            let imageType: ImageType = [.avatar, .photo, .thumbnail, .fullSize].randomElement()!

            let size: Int
            switch imageType {
            case .avatar:
                size = 100
            case .photo:
                size = 400
            case .thumbnail:
                size = 200
            case .fullSize:
                size = 800
            }

            // Use multiple image services for variety
            let service = i % 3
            let url: URL

            switch service {
            case 0:
                // Picsum Photos
                url = URL(string: "https://picsum.photos/id/\(i % 100)/\(size)")!
            case 1:
                // Placeholder.com
                url = URL(string: "https://via.placeholder.com/\(size)")!
            default:
                // DummyImage
                let color = ["FF6B6B", "4ECDC4", "45B7D1", "FFA07A", "98D8C8"].randomElement()!
                url = URL(string: "https://dummyimage.com/\(size)x\(size)/\(color)/ffffff")!
            }

            let item = ImageItem(
                url: url,
                title: "Image \(i + 1)",
                subtitle: "\(size)×\(size) - \(imageType)",
                imageType: imageType
            )

            items.append(item)
        }

        return items
    }
    
    static func generateSingleItem() -> ImageItem {
        .init(
            url: URL(string: "https://picsum.photos/id/100/400")!,
            title: "Image 1",
            subtitle: "400×400 - Avatar",
            imageType: .avatar
        )
    }
}

// MARK: - ImageType Extension

extension ImageItem.ImageType: CustomStringConvertible {
    var description: String {
        switch self {
        case .avatar: return "Avatar"
        case .photo: return "Photo"
        case .thumbnail: return "Thumbnail"
        case .fullSize: return "Full Size"
        }
    }
}
