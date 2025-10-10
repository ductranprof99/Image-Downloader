//
//  CacheLatencyDemoView.swift
//  CacheLatency
//
//  Interactive demo showing cache latency behavior
//

import SwiftUI

struct CacheLatencyDemoView: View {
    @StateObject private var viewModel = CacheLatencyViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Cache Configuration
                    cacheConfigSection

                    // Cache Statistics
                    cacheStatsSection

                    // Action Buttons
                    actionButtonsSection

                    // High Latency Images
                    if !viewModel.highLatencyImages.isEmpty {
                        highLatencySection
                    }

                    // Low Latency Images
                    if !viewModel.lowLatencyImages.isEmpty {
                        lowLatencySection
                    }
                }
                .padding()
            }
            .navigationTitle("Cache Latency Demo")
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var cacheConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cache Configuration")
                .font(.headline)

            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("High Latency Limit:")
                        Spacer()
                        Text("\(viewModel.highLatencyLimit)")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.highLatencyLimit) },
                        set: { viewModel.highLatencyLimit = Int($0) }
                    ), in: 5...50, step: 5)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Low Latency Limit:")
                        Spacer()
                        Text("\(viewModel.lowLatencyLimit)")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(viewModel.lowLatencyLimit) },
                        set: { viewModel.lowLatencyLimit = Int($0) }
                    ), in: 5...50, step: 5)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private var cacheStatsSection: some View {
        Group {
            if let stats = viewModel.cacheStats {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cache Statistics")
                        .font(.headline)

                    VStack(spacing: 12) {
                        // High Latency Stats
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("High Latency Cache:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(stats.highLatencyCount) / \(stats.highLatencyLimit)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)

                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(
                                            width: geometry.size.width * CGFloat(stats.highLatencyPercentage / 100),
                                            height: 8
                                        )
                                }
                                .cornerRadius(4)
                            }
                            .frame(height: 8)
                        }

                        // Low Latency Stats
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Low Latency Cache:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(stats.lowLatencyCount) / \(stats.lowLatencyLimit)")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)

                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(
                                            width: geometry.size.width * CGFloat(stats.lowLatencyPercentage / 100),
                                            height: 8
                                        )
                                }
                                .cornerRadius(4)
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.loadHighLatencyImages()
                }) {
                    Text("Load High Latency")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)

                Button(action: {
                    viewModel.loadLowLatencyImages()
                }) {
                    Text("Load Low Latency")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
            }

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.clearHighLatencyCache()
                }) {
                    Text("Clear High Cache")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    viewModel.clearLowLatencyCache()
                }) {
                    Text("Clear Low Cache")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.clearLayout()
                }) {
                    Text("Clear Layout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    viewModel.clearCache()
                }) {
                    Text("Clear All Cache")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var highLatencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("High Latency Images (\(viewModel.highLatencyImages.count))")
                .font(.headline)
                .foregroundColor(.blue)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(Array(viewModel.highLatencyImages.keys.sorted()), id: \.self) { urlString in
                    if let image = viewModel.highLatencyImages[urlString] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }

    private var lowLatencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Low Latency Images (\(viewModel.lowLatencyImages.count))")
                .font(.headline)
                .foregroundColor(.green)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(Array(viewModel.lowLatencyImages.keys.sorted()), id: \.self) { urlString in
                    if let image = viewModel.lowLatencyImages[urlString] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    CacheLatencyDemoView()
}
