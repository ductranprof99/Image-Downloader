//
//  ImageItem.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
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
}
