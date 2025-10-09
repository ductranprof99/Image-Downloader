//
//  NetworkCustomDemoView.swift
//  NetworkDownloader
//
//  Created by ductd on 9/10/25.
//


import SwiftUI
import ImageDownloader

struct NetworkCustomDemoView: View {

    @StateObject private var viewModel = NetworkCustomViewModel()
    @State private var customURL: String = "https://picsum.photos/200/300"
    @State private var showingURLInput = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Retry Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Retry Policy")
                            .font(.headline)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Max Retries")
                                Spacer()
                                Stepper("\(viewModel.maxRetries)", value: $viewModel.maxRetries, in: 0...10)
                                    .onChange(of: viewModel.maxRetries) {
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            HStack {
                                Text("Base Delay")
                                Spacer()
                                Stepper(String(format: "%.1fs", viewModel.baseDelay), value: $viewModel.baseDelay, in: 0.1...5.0, step: 0.5)
                                    .onChange(of: viewModel.baseDelay) {
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            Toggle("Enable Logging", isOn: $viewModel.enableRetryLogging)
                                .onChange(of: viewModel.enableRetryLogging) {
                                    viewModel.updateNetworkConfig()
                                }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Custom Headers
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Headers")
                            .font(.headline)

                        VStack(spacing: 8) {
                            Toggle("Add User-Agent", isOn: $viewModel.addUserAgent)
                                .onChange(of: viewModel.addUserAgent) {
                                    viewModel.updateNetworkConfig()
                                }

                            Toggle("Add API Key", isOn: $viewModel.addAPIKey)
                                .onChange(of: viewModel.addAPIKey) { 
                                    viewModel.updateNetworkConfig()
                                }

                            if viewModel.addUserAgent || viewModel.addAPIKey {
                                Text("Active Headers:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ForEach(viewModel.activeHeaders, id: \.key) { header in
                                    HStack {
                                        Text(header.key)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text(header.value)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Divider()

                    // Test Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Test Network Loading")
                            .font(.headline)

                        Button(action: {
                            showingURLInput = true
                        }) {
                            Label("Enter Custom URL", systemImage: "link")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        // Current URL
                        if !viewModel.currentTestURL.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current URL:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(viewModel.currentTestURL)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal)
                        }

                        // Load button
                        Button(action: {
                            viewModel.loadSingleTestImage()
                        }) {
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Loading...")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Label("Load Image", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading || viewModel.currentTestURL.isEmpty)

                        // Progress
                        if viewModel.isLoading {
                            ProgressView(value: viewModel.progress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }

                        // Result
                        if let image = viewModel.loadedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        }

                        // Stats
                        if let stats = viewModel.loadStats {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Load Time:")
                                        .font(.caption)
                                    Spacer()
                                    Text(stats.loadTimeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Source:")
                                        .font(.caption)
                                    Spacer()
                                    Text(stats.source)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Retry Count:")
                                        .font(.caption)
                                    Spacer()
                                    Text("\(stats.retryCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Error
                        if let error = viewModel.loadError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Network Custom")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingURLInput) {
                URLInputSheet(url: $customURL) {
                    viewModel.currentTestURL = customURL
                    showingURLInput = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NetworkCustomDemoView()
}

