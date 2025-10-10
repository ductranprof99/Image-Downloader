//
//  NetworkCustomDemoView1.swift
//  NetworkDownloader
//
//  Created by ductd on 9/10/25.
//



import SwiftUI
import ImageDownloader

struct NetworkRequestDemoView: View {

    @StateObject private var viewModel = NetworkRequestViewModel()
    let listImage = [
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
    
    @State private var only4Item = false

    var displayList: [String] {
        only4Item ? Array(listImage.prefix(4)) : listImage
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Network Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Network Configuration")
                            .font(.headline)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Max Concurrent")
                                Spacer()
                                Stepper("\(viewModel.maxConcurrent)", value: $viewModel.maxConcurrent, in: 1...20)
                                    .onChange(of: viewModel.maxConcurrent) {
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            HStack {
                                Text("Timeout")
                                Spacer()
                                Stepper("\(Int(viewModel.timeout))s", value: $viewModel.timeout, in: 5...120, step: 5)
                                    .onChange(of: viewModel.timeout) { _, _ in
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            Toggle("Allow Cellular", isOn: $viewModel.allowsCellular)
                                .onChange(of: viewModel.allowsCellular) {
                                    viewModel.updateNetworkConfig()
                                }
                            
                            Toggle("Short list", isOn: $only4Item)

                            // Note: Background downloads handled automatically by URLSession
                            Text("Background Downloads: Enabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Divider()

                    // Buttons Section
                    HStack(spacing: 12) {
                        // Load All Button
                        Button(action: {
                            viewModel.loadMultipleImages(urls: displayList)
                        }) {
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Loading...")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Label("Load All Images", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)

                        // Reset Button
                        Button(action: {
                            viewModel.resetAll()
                        }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }

                    // Images List
                    VStack(spacing: 16) {
                        ForEach(displayList, id: \.self) { urlString in
                            ImageRowView(
                                urlString: urlString,
                                image: viewModel.loadedImages[urlString],
                                progress: viewModel.imageProgress[urlString] ?? 0.0,
                                error: viewModel.imageErrors[urlString]
                            )
                        }
                    }
                }
                .padding()
                
                
            }
            .navigationTitle("Multiple Images")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Image Row View
struct ImageRowView: View {
    let urlString: String
    let image: UIImage?
    let progress: Double
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(urlString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                Spacer()
            }

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green, lineWidth: 2)
                    )
            } else if let error = error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview
#Preview {
    NetworkRequestDemoView()
}

