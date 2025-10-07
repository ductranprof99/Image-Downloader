//
//  StorageImageView.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import SwiftUI
import ImageDownloader

struct StorageImageView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true
    @AppStorage("useHighPriority") private var useHighPriority = false

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
            
            Toggle(isOn: $useHighPriority) {
                Text(useHighPriority ? "High Priority" : "Low Priority")
            }
            .padding(.horizontal)
            .onChange(of: useHighPriority) { 
                Task {
                    self.isLoading = true
                    self.image = nil
                    await loadImage()
                }
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        do {
            let result = try await ImageDownloaderManager.shared.requestImageAsync(
                at: url,
                priority: useHighPriority ? .high : .low,
                shouldSaveToStorage: !useHighPriority  // Save to storage only for low priority
            )
            
            await MainActor.run {
                if useHighPriority {
                    // In high priority mode, only show from cache or storage
                    if result.fromCache || result.fromStorage {
                        self.image = result.image
                    }
                } else {
                    // In low priority mode, show from any source
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
