//
//  ImageItem.swift
//  Storage
//
//  Created by ductd on 9/10/25.
//



import Foundation

// MARK: - ImageItem Helper
struct ImageItem: Identifiable {
    let id = UUID()
    let url: URL
    let title: String

    static func generateSampleData(count: Int) -> [ImageItem] {
        (0..<count).map { index in
            // Use picsum.photos for random images
            let imageId = Int.random(in: 1...1000)
            let width = [200, 300, 400].randomElement()!
            let height = [200, 300, 400].randomElement()!
            let url = URL(string: "https://picsum.photos/id/\(imageId)/\(width)/\(height)")!

            return ImageItem(
                url: url,
                title: "Image \(index + 1)"
            )
        }
    }
    
    static func fixedData() -> [ImageItem] {
        let listImage = [
            "https://picsum.photos/id/299/400/300",
            "https://picsum.photos/id/871/300/300",
            "https://picsum.photos/id/904/400/300",
            "https://picsum.photos/id/680/400/200",
            "https://picsum.photos/id/579/200/400",
            "https://picsum.photos/id/460/300/300",
            "https://picsum.photos/id/737/400/300",
            "https://picsum.photos/id/181/200/300",
            "https://picsum.photos/id/529/400/400",
            "https://picsum.photos/id/94/300/200",
            "https://picsum.photos/id/500/400/300",
            "https://picsum.photos/id/422/400/300",
            "https://picsum.photos/id/952/300/200",
            "https://picsum.photos/id/798/200/300",
            "https://picsum.photos/id/150/300/400",
            "https://picsum.photos/id/42/400/200",
            "https://picsum.photos/id/813/300/400",
            "https://picsum.photos/id/187/300/400",
            "https://picsum.photos/id/236/400/300",
            "https://picsum.photos/id/33/200/20"
        ]
        return (0..<listImage.count).map { idx in
            let url = URL(string: listImage[idx])!
            return ImageItem(
                url: url,
                title: "Image \(idx + 1)"
            )
        }
    }
}
