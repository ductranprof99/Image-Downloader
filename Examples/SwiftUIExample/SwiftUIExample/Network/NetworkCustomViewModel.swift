
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
