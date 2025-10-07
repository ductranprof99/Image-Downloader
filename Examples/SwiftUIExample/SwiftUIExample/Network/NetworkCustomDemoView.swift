//
//  NetworkCustomDemoView.swift
//  ImageDownloader
//
//  Demo showing custom network configurations for image loading
//

import SwiftUI
import ImageDownloader

@available(iOS 15.0, *)
struct NetworkCustomDemoView: View {

    @StateObject private var viewModel = NetworkCustomViewModel()
    @State private var customURL: String = "https://picsum.photos/200/300"
    @State private var showingURLInput = false

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
                                    .onChange(of: viewModel.maxConcurrent) { _ in
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            HStack {
                                Text("Timeout")
                                Spacer()
                                Stepper("\(Int(viewModel.timeout))s", value: $viewModel.timeout, in: 5...120, step: 5)
                                    .onChange(of: viewModel.timeout) { _ in
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            Toggle("Allow Cellular", isOn: $viewModel.allowsCellular)
                                .onChange(of: viewModel.allowsCellular) { _ in
                                    viewModel.updateNetworkConfig()
                                }

                            Toggle("Background Tasks", isOn: $viewModel.enableBackgroundTasks)
                                .onChange(of: viewModel.enableBackgroundTasks) { _ in
                                    viewModel.updateNetworkConfig()
                                }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Retry Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Retry Policy")
                            .font(.headline)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Max Retries")
                                Spacer()
                                Stepper("\(viewModel.maxRetries)", value: $viewModel.maxRetries, in: 0...10)
                                    .onChange(of: viewModel.maxRetries) { _ in
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            HStack {
                                Text("Base Delay")
                                Spacer()
                                Stepper(String(format: "%.1fs", viewModel.baseDelay), value: $viewModel.baseDelay, in: 0.1...5.0, step: 0.5)
                                    .onChange(of: viewModel.baseDelay) { _ in
                                        viewModel.updateNetworkConfig()
                                    }
                            }

                            Toggle("Enable Logging", isOn: $viewModel.enableRetryLogging)
                                .onChange(of: viewModel.enableRetryLogging) { _ in
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
                                .onChange(of: viewModel.addUserAgent) { _ in
                                    viewModel.updateNetworkConfig()
                                }

                            Toggle("Add API Key", isOn: $viewModel.addAPIKey)
                                .onChange(of: viewModel.addAPIKey) { _ in
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
                            viewModel.loadTestImage()
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

@available(iOS 15.0, *)
class NetworkCustomViewModel: ObservableObject {
    // Network config
    @Published var maxConcurrent: Int = 4
    @Published var timeout: TimeInterval = 30
    @Published var allowsCellular: Bool = true
    @Published var enableBackgroundTasks: Bool = true

    // Retry config
    @Published var maxRetries: Int = 3
    @Published var baseDelay: TimeInterval = 1.0
    @Published var enableRetryLogging: Bool = false

    // Headers
    @Published var addUserAgent: Bool = false
    @Published var addAPIKey: Bool = false
    @Published var activeHeaders: [(key: String, value: String)] = []

    // Test state
    @Published var currentTestURL: String = "https://picsum.photos/400/600"
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0.0
    @Published var loadedImage: UIImage?
    @Published var loadError: String?
    @Published var loadStats: LoadStats?

    private var customConfig: IDConfiguration?
    private var loadStartTime: Date?

    func updateNetworkConfig() {
        // Build custom headers
        var headers: [String: String]? = nil
        if addUserAgent || addAPIKey {
            headers = [:]
            if addUserAgent {
                headers?["User-Agent"] = "ImageDownloader-Demo/1.0"
            }
            if addAPIKey {
                headers?["X-API-Key"] = "demo-key-12345"
            }

            activeHeaders = headers?.map { (key: $0.key, value: $0.value) } ?? []
        } else {
            activeHeaders = []
        }

        // Create retry policy
        let retryPolicy = IDRetryPolicy(
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            backoffMultiplier: 2.0,
            maxDelay: 60.0
        )

        // Build config using ConfigBuilder
        customConfig = ConfigBuilder()
            .maxConcurrentDownloads(maxConcurrent)
            .timeout(timeout)
            .allowsCellularAccess(allowsCellular)
            .retryPolicy(RetryPolicy(
                maxRetries: maxRetries,
                baseDelay: baseDelay,
                backoffMultiplier: 2.0
            ))
            .customHeaders(headers)
            .enableDebugLogging(enableRetryLogging)
            .build()
    }

    func loadTestImage() {
        guard let url = URL(string: currentTestURL) else {
            loadError = "Invalid URL"
            return
        }

        isLoading = true
        progress = 0.0
        loadedImage = nil
        loadError = nil
        loadStats = nil
        loadStartTime = Date()

        updateNetworkConfig()

        let manager = ImageDownloaderManager.instance(for: customConfig)

        manager.requestImage(
            at: url,
            priority: .high,
            shouldSaveToStorage: true,
            progress: { [weak self] progressValue in
                DispatchQueue.main.async {
                    self?.progress = progressValue
                }
            },
            completion: { [weak self] image, error, fromCache, fromStorage in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    self.isLoading = false

                    if let image = image {
                        self.loadedImage = image

                        let loadTime = Date().timeIntervalSince(self.loadStartTime ?? Date())
                        let source = fromCache ? "Cache" : (fromStorage ? "Storage" : "Network")

                        self.loadStats = LoadStats(
                            loadTime: loadTime,
                            source: source,
                            retryCount: 0 // We don't track this in the callback
                        )
                    } else if let error = error {
                        self.loadError = error.localizedDescription
                    }
                }
            },
            caller: self
        )
    }
}

struct LoadStats {
    let loadTime: TimeInterval
    let source: String
    let retryCount: Int

    var loadTimeString: String {
        String(format: "%.2fs", loadTime)
    }
}

@available(iOS 15.0, *)
struct URLInputSheet: View {
    @Binding var url: String
    var onSubmit: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Image URL")
                    .font(.headline)

                TextField("https://example.com/image.jpg", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                // Quick presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Presets:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Random 400x600") {
                        url = "https://picsum.photos/400/600"
                    }
                    .buttonStyle(.bordered)

                    Button("Random 800x600") {
                        url = "https://picsum.photos/800/600"
                    }
                    .buttonStyle(.bordered)

                    Button("Specific Dog Image") {
                        url = "https://picsum.photos/id/237/400/400"
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(action: {
                    onSubmit()
                }) {
                    Text("Load URL")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Custom URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct NetworkCustomDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkCustomDemoView()
    }
}
