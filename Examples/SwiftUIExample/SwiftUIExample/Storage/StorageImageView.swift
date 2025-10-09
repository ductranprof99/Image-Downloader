//
//  StorageImageView.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import SwiftUI
import ImageDownloader

enum StorageMode: Int, CaseIterable {
    case noStorage = 0
    case withStorage = 1
    
    var description: String {
        switch self {
        case .noStorage:
            return "No Storage"
        case .withStorage:
            return "Storage"
        }
    }
    
    var configuration: ResourcePriority {
        switch self {
        case .noStorage:
            return .low
        case .highPriorityLowStorage:
            return
        case .lowPriorityWithStorage:
            return (.low, true)
        }
    }
}

struct StorageImageView: View {
    let url: URL
    @Binding var mode: StorageMode
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        VStack {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(8)
                } else if isLoading {
                    Color.gray.opacity(0.2)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .overlay(
                            Image("photo.slash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(20)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        do {
            let config = mode.configuration
            let result = try await ImageDownloaderManager.shared.requestImageAsync(
                at: url,
                priority: config.priority,
                shouldSaveToStorage: config.shouldSaveToStorage
            )
            
            await MainActor.run {
                switch mode {
                case .noStorage:
                    // Only show if from cache
                    if result.fromCache {
                        self.image = result.image
                    }
                case .highPriorityLowStorage:
                    // High priority: show if from cache or storage
                    if result.fromCache || result.fromStorage {
                        self.image = result.image
                    }
                case .lowPriorityWithStorage:
                    // Low priority with storage: show from any source
                    self.image = result.image
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
