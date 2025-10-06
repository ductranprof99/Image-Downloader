# ImageDownloader - Complete Documentation

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2013%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.1.0-green.svg)](https://github.com/ductranprof99/Image-Downloader)

A powerful, production-ready Swift image downloading library with advanced caching, async/await support, protocol-based injectable configuration, and full customization.

**Current Version**: 2.1.0

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Features](#features)
3. [Installation](#installation)
4. [Basic Usage](#basic-usage)
5. [Injectable Configuration System](#injectable-configuration-system)
6. [Network Features](#network-features)
7. [Advanced Usage](#advanced-usage)
8. [Migration Guide](#migration-guide)
9. [API Reference](#api-reference)
10. [Additional Resources](#additional-resources)

---

## Quick Start

### Simple Usage

```swift
import ImageDownloader

// Async/await (modern Swift)
let image = try await UIImage.load(from: imageURL)
imageView.image = image

// UIImageView extension
imageView.setImage(with: imageURL, placeholder: placeholderImage)
```

### With Custom Configuration

```swift
// Use preset configuration
let image = try await UIImage.load(from: imageURL, config: FastConfig.shared)

// Or build custom config
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .retryPolicy(.aggressive)
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .build()

let image = try await UIImage.load(from: imageURL, config: config)
```

---

## Features

### Core Features

- 🚀 **Modern Swift Concurrency** - Built-in async/await support
- 💾 **Intelligent Caching** - Two-tier memory cache (high/low priority)
- 📦 **Persistent Storage** - Automatic disk caching with customizable compression
- 🎨 **Protocol-Based Injectable Config** - Different configs per request
- 🔄 **Objective-C Compatible** - Full bridging for legacy codebases
- ⚡️ **Production Ready** - Battle-tested architecture

### Network Features (v2.1)

- 🔁 **Retry with Exponential Backoff** - Intelligent retry for failed downloads
- 🔗 **Request Deduplication** - Prevents duplicate concurrent requests
- 🔐 **Custom Headers & Authentication** - Add auth tokens, API keys
- 📡 **Network Reachability** - Monitor WiFi/cellular status
- ⏱️ **Timeout Control** - Configurable request timeouts
- 📱 **Cellular Control** - WiFi-only mode available

### Configuration Features (v2.1)

- ⚙️ **Injectable Configuration** - Pass config per request
- 🎯 **Preset Configs** - FastConfig, OfflineFirstConfig, LowMemoryConfig
- 🔨 **Fluent Builder API** - Easy custom config creation
- 🧪 **Testable** - Easy to mock and inject configs
- 🔄 **Backward Compatible** - Old code still works

---

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ductranprof99/Image-Downloader.git", from: "2.1.0")
]
```

Or add via Xcode: **File → Add Packages**

---

## Basic Usage

### 1. UIImage Extension (Simplest)

```swift
import ImageDownloader

// Async/await
let image = try await UIImage.load(from: imageURL)
imageView.image = image

// With completion handler
UIImage.load(from: imageURL) { result in
    switch result {
    case .success(let image):
        imageView.image = image
    case .failure(let error):
        print("Error: \(error)")
    }
}

// With progress tracking
UIImage.load(
    from: imageURL,
    progress: { progress in
        progressView.progress = Float(progress)
    },
    completion: { result in
        // Handle result
    }
)
```

### 2. UIImageView Extension

```swift
import ImageDownloaderUI

// Simple
imageView.setImage(with: imageURL)

// With placeholder
imageView.setImage(
    with: imageURL,
    placeholder: UIImage(named: "placeholder")
)

// With priority
imageView.setImage(
    with: imageURL,
    placeholder: placeholderImage,
    priority: .high
)

// Full featured
imageView.setImage(
    with: imageURL,
    placeholder: placeholderImage,
    priority: .high,
    onProgress: { progress in
        print("Loading: \(Int(progress * 100))%")
    },
    onCompletion: { image, error, fromCache, fromStorage in
        if fromCache {
            print("✅ From cache")
        }
    }
)
```

### 3. Direct Manager Access

```swift
import ImageDownloader

// Async/await
let result = try await ImageDownloaderManager.shared.requestImage(at: imageURL)
imageView.image = result.image
print("From cache: \(result.fromCache)")

// Completion handler
ImageDownloaderManager.shared.requestImage(at: imageURL) { image, error, fromCache, fromStorage in
    if let image = image {
        imageView.image = image
    }
}
```

---

## Injectable Configuration System

### Philosophy

Instead of global configuration, **inject config per request**:

```swift
// ✅ New way: Different configs for different use cases
let avatar = try await UIImage.load(from: avatarURL, config: FastConfig.shared)
let photo = try await UIImage.load(from: photoURL, config: OfflineFirstConfig.shared)

// ⚠️ Old way: One global config for everything
ImageDownloaderManager.shared.configure(globalConfig)
```

### Configuration Protocols

```
ImageDownloaderConfigProtocol (main)
├── NetworkConfigProtocol (downloads, retry, auth)
├── CacheConfigProtocol (memory cache)
└── StorageConfigProtocol (disk storage, compression)
```

### Preset Configurations

#### 1. DefaultConfig - Balanced Settings

```swift
let config = DefaultConfig.shared
// - 4 concurrent downloads
// - 30s timeout
// - 50/100 cache limits
// - Default retry
```

#### 2. FastConfig - High Performance

```swift
let config = FastConfig.shared
// - 8 concurrent downloads
// - 20s timeout
// - 100/200 cache limits
// - Aggressive retry
// - JPEG compression (faster I/O)
```

#### 3. OfflineFirstConfig - Poor Connectivity

```swift
let config = OfflineFirstConfig.shared
// - WiFi only
// - 2 concurrent downloads
// - 200/500 cache limits (huge!)
// - Conservative retry
// - Adaptive compression
```

#### 4. LowMemoryConfig - Memory Constrained

```swift
let config = LowMemoryConfig.shared
// - 2 concurrent downloads
// - 20/50 cache limits (minimal)
// - Aggressive memory cleanup
// - High JPEG compression
```

### ConfigBuilder - Fluent API

```swift
// Start from scratch
let config = ConfigBuilder()
    .maxConcurrentDownloads(6)
    .timeout(30)
    .retryPolicy(.aggressive)
    .cacheSize(high: 100, low: 200)
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .customHeaders([
        "User-Agent": "MyApp/1.0",
        "Accept": "image/webp,image/*"
    ])
    .authenticationHandler { request in
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .enableDebugLogging()
    .build()

// Or start from preset and override
let config = ConfigBuilder.fast()
    .timeout(60)  // Just override what you need
    .customHeaders(["X-App": "MyApp"])
    .build()
```

### Custom Configuration

```swift
struct MyAppConfig: ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol = MyNetworkConfig()
    var cacheConfig: CacheConfigProtocol = DefaultCacheConfig()
    var storageConfig: StorageConfigProtocol = MyStorageConfig()
    var enableDebugLogging = false
}

struct MyNetworkConfig: NetworkConfigProtocol {
    var maxConcurrentDownloads = 8
    var timeout: TimeInterval = 30
    var retryPolicy = RetryPolicy.aggressive
    var customHeaders: [String: String]? = [
        "User-Agent": "MyApp/1.0"
    ]
    var authenticationHandler: ((inout URLRequest) -> Void)? = { request in
        request.setValue("Bearer \(AuthManager.token)", forHTTPHeaderField: "Authorization")
    }
    var allowsCellularAccess = true
}

// Usage
let image = try await UIImage.load(from: url, config: MyAppConfig())
```

### Usage Patterns

#### Pattern 1: App-Wide Configs

```swift
extension ImageDownloaderConfigProtocol {
    static let avatar = FastConfig.shared
    static let photo = OfflineFirstConfig.shared
    static let thumbnail = LowMemoryConfig.shared
}

// Usage
avatarImageView.setImage(with: avatarURL, config: .avatar)
photoImageView.setImage(with: photoURL, config: .photo)
thumbImageView.setImage(with: thumbURL, config: .thumbnail)
```

#### Pattern 2: Per-Environment Configs

```swift
enum Environment {
    case development, staging, production

    var imageConfig: ImageDownloaderConfigProtocol {
        switch self {
        case .development:
            return ConfigBuilder()
                .enableDebugLogging()
                .timeout(60)
                .build()
        case .staging:
            return DefaultConfig.shared
        case .production:
            return FastConfig.shared
        }
    }
}

// Usage
let config = Environment.current.imageConfig
```

---

## Network Features

### 1. Retry with Exponential Backoff

Automatically retries failed downloads with intelligent backoff.

```swift
// Use preset retry policy
let config = ConfigBuilder()
    .retryPolicy(.default)  // 3 retries, 1s base, 2x multiplier
    .build()

// Or create custom policy
let customPolicy = RetryPolicy(
    maxRetries: 5,
    baseDelay: 0.5,
    backoffMultiplier: 2.0,
    maxDelay: 30.0
)

let config = ConfigBuilder()
    .retryPolicy(customPolicy)
    .build()
```

**Retry Timeline Example** (default policy):
- First attempt fails → Retry in 1s
- Second attempt fails → Retry in 2s
- Third attempt fails → Retry in 4s
- Fourth attempt fails → Give up

**What gets retried:**
- ✅ Network timeouts
- ✅ Connection lost
- ✅ Server errors (5xx)
- ✅ Rate limiting (429)
- ❌ Cancelled requests
- ❌ Invalid URLs
- ❌ Client errors (4xx)

### 2. Request Deduplication

Prevents duplicate concurrent requests for the same URL.

```swift
// Multiple views request same image
imageView1.setImage(with: url)  // Starts download
imageView2.setImage(with: url)  // Joins existing download
imageView3.setImage(with: url)  // Joins existing download

// Only ONE network request is made!
// All three views get the image when it completes
```

**Benefits:**
- Saves 50-90% bandwidth in list/grid views
- Prevents server overload
- Faster overall performance

### 3. Custom Headers & Authentication

Add custom HTTP headers and authentication to requests.

```swift
// Via ConfigBuilder
let config = ConfigBuilder()
    .customHeaders([
        "User-Agent": "MyApp/1.0",
        "Accept": "image/webp,image/*",
        "X-API-Key": "secret_key"
    ])
    .authenticationHandler { request in
        let token = KeychainManager.getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .build()

// Or via Manager helpers
ImageDownloaderManager.shared.setCustomHeaders([
    "User-Agent": "MyApp/1.0"
])

ImageDownloaderManager.shared.setAuthenticationHandler { request in
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

**Use Cases:**
- Private CDN with API keys
- OAuth authentication
- Analytics headers
- Content negotiation (request WebP/AVIF)

### 4. Network Reachability Monitoring

Monitor network status and connection type.

```swift
import ImageDownloader

// Start monitoring
NetworkMonitor.shared.startMonitoring()

// Listen for changes
NetworkMonitor.shared.onReachabilityChange = { isReachable in
    if isReachable {
        print("Network is back!")
    } else {
        print("Network lost!")
    }
}

NetworkMonitor.shared.onConnectionTypeChange = { isWiFi, isCellular in
    if isCellular {
        print("Switched to cellular - reduce quality")
    }
}

// Check current status
if NetworkMonitor.shared.isReachable {
    print("Status: \(NetworkMonitor.shared.statusDescription)")
}

if NetworkMonitor.shared.isExpensive {
    print("Using expensive connection")
}
```

**WiFi-Only Mode:**

```swift
let config = ConfigBuilder()
    .allowsCellularAccess(false)  // WiFi only
    .build()
```

### 5. Timeout Control

```swift
let config = ConfigBuilder()
    .timeout(60)  // 60 seconds
    .build()

// Or update dynamically
ImageDownloaderManager.shared.setTimeout(60)
```

---

## Advanced Usage

### Progress Tracking

#### UIKit - Simple & Direct

```swift
class MyViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!

    func loadImage() {
        imageView.setImage(
            with: imageURL,
            placeholder: placeholderImage,
            onProgress: { [weak self] progress in
                // Update progress bar
                self?.progressView.progress = Float(progress)
                self?.progressView.isHidden = (progress >= 1.0)
            },
            onCompletion: { [weak self] image, error, fromCache, fromStorage in
                self?.progressView.isHidden = true
            }
        )
    }
}
```

#### SwiftUI - Use ImageLoader

```swift
import SwiftUI
import ImageDownloader

struct PhotoView: View {
    let imageURL: URL
    @StateObject private var loader = ImageLoader()

    var body: some View {
        VStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if loader.isLoading {
                ProgressView(value: loader.progress, total: 1.0)
                Text("\(Int(loader.progress * 100))%")
            }
        }
        .onAppear {
            loader.load(from: imageURL)
        }
    }
}
```

**ImageLoader** is an `ObservableObject` that bridges progress callbacks to SwiftUI:

```swift
@StateObject private var loader = ImageLoader()

// Properties available:
loader.image        // UIImage?
loader.isLoading    // Bool
loader.progress     // CGFloat (0.0 to 1.0)
loader.error        // Error?

// Methods:
loader.load(from: url, config: config, priority: .high)
loader.cancel()
```

### Priority Management

```swift
// High priority (loads first)
avatarImageView.setImage(with: avatarURL, priority: .high)

// Low priority (loads when high priority done)
backgroundImageView.setImage(with: bgURL, priority: .low)
```

### Cancellation

```swift
// Cancel specific view's request
imageView.cancelImageLoading()

// Cancel all requests for URL
ImageDownloaderManager.shared.cancelRequest(for: url, caller: self)
```

### Cache Management

```swift
// Clear specific URL
ImageDownloaderManager.shared.clearCache(for: url)

// Clear all cache
ImageDownloaderManager.shared.clearAllCache()

// Clear only low priority cache
ImageDownloaderManager.shared.clearLowPriorityCache()

// Get cache statistics
let highCount = ImageDownloaderManager.shared.cacheSizeHigh()
let lowCount = ImageDownloaderManager.shared.cacheSizeLow()
let storageBytes = ImageDownloaderManager.shared.storageSizeBytes()
print("Cache: \(highCount) high, \(lowCount) low, \(storageBytes) bytes storage")
```

### Storage Customization

```swift
// Use JPEG compression (saves 50-80% disk space)
let config = ConfigBuilder()
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .build()

// Use adaptive compression (automatic based on image type)
let config = ConfigBuilder()
    .compressionProvider(AdaptiveCompressionProvider())
    .build()

// Hierarchical storage (organize by domain)
let config = ConfigBuilder()
    .pathProvider(DomainHierarchicalPathProvider())
    .build()
```

### Observers

```swift
class MyObserver: ImageDownloaderObserver {
    func imageDownloaderDidStart(url: URL) {
        print("Started: \(url)")
    }

    func imageDownloaderDidComplete(url: URL, image: UIImage?, error: Error?) {
        if let image = image {
            print("Completed: \(url)")
        }
    }

    func imageDownloaderDidUpdateProgress(url: URL, progress: CGFloat) {
        print("Progress: \(Int(progress * 100))%")
    }
}

let observer = MyObserver()
ImageDownloaderManager.shared.addObserver(observer)
```

---

## Migration Guide

For complete migration instructions, see **[Migration Guide](markdown/MIGRATION_GUIDE.md)**

### Quick Migration Reference

- **v1.x → v2.0+**: Package names changed from `CNI` to `ImageDownloader`
- **v2.0 → v2.1**: 100% backward compatible, new features are opt-in

See the [full migration guide](markdown/MIGRATION_GUIDE.md) for detailed instructions and examples

---

## API Reference

### UIImage Extension

```swift
// Async/await
static func load(
    from url: URL,
    config: ImageDownloaderConfigProtocol? = nil,
    priority: ResourcePriority = .normal
) async throws -> UIImage

static func load(
    from urlString: String,
    config: ImageDownloaderConfigProtocol? = nil,
    priority: ResourcePriority = .normal
) async throws -> UIImage

// Completion handler
static func load(
    from url: URL,
    config: ImageDownloaderConfigProtocol? = nil,
    priority: ResourcePriority = .normal,
    progress: ((CGFloat) -> Void)? = nil,
    completion: @escaping (Result<UIImage, Error>) -> Void
)
```

### UIImageView Extension

```swift
// New injectable config API
func setImage(
    with url: URL,
    config: ImageDownloaderConfigProtocol? = nil,
    placeholder: UIImage? = nil,
    priority: ResourcePriority = .low,
    onProgress: ((CGFloat) -> Void)? = nil,
    onCompletion: ((UIImage?, Error?, Bool, Bool) -> Void)? = nil
)

// Legacy (still supported)
func setImage(with url: URL)
func setImage(with url: URL, placeholder: UIImage?)
func setImage(with url: URL, placeholder: UIImage?, priority: ResourcePriority)

// Cancel
func cancelImageLoading()
```

### ImageDownloaderManager

```swift
// Singleton & Factory
static let shared: ImageDownloaderManager
static func instance(for config: ImageDownloaderConfigProtocol?) -> ImageDownloaderManager

// Async/await
func requestImage(
    at url: URL,
    priority: ResourcePriority = .low,
    shouldSaveToStorage: Bool? = nil,
    progress: ImageProgressBlock? = nil,
    caller: AnyObject? = nil
) async throws -> ImageResult

// Completion handler
func requestImage(
    at url: URL,
    priority: ResourcePriority = .low,
    shouldSaveToStorage: Bool? = nil,
    progress: ImageProgressBlock? = nil,
    completion: ImageCompletionBlock?,
    caller: AnyObject? = nil
)

// Configuration
func configure(_ configuration: ImageDownloaderConfiguration)
func setCustomHeaders(_ headers: [String: String])
func setAuthenticationHandler(_ handler: @escaping (inout URLRequest) -> Void)
func setRetryPolicy(_ policy: RetryPolicy)
func setTimeout(_ timeout: TimeInterval)
func setAllowsCellularAccess(_ allowed: Bool)

// Cache management
func clearCache(for url: URL)
func clearAllCache()
func clearLowPriorityCache()
func cacheSizeHigh() -> Int
func cacheSizeLow() -> Int
func storageSizeBytes() -> UInt

// Observers
func addObserver(_ observer: ImageDownloaderObserver)
func removeObserver(_ observer: ImageDownloaderObserver)
```

### ConfigBuilder

```swift
// Network
func maxConcurrentDownloads(_ count: Int) -> Self
func timeout(_ seconds: TimeInterval) -> Self
func retryPolicy(_ policy: RetryPolicy) -> Self
func customHeaders(_ headers: [String: String]) -> Self
func authenticationHandler(_ handler: @escaping (inout URLRequest) -> Void) -> Self
func allowsCellularAccess(_ allowed: Bool) -> Self

// Cache
func cacheSize(high: Int, low: Int) -> Self

// Storage
func enableStorage(_ enabled: Bool) -> Self
func compressionProvider(_ provider: any ImageCompressionProvider) -> Self
func pathProvider(_ provider: any StoragePathProvider) -> Self

// Debug
func enableDebugLogging(_ enabled: Bool = true) -> Self

// Build
func build() -> ImageDownloaderConfigProtocol

// Presets
static func fast() -> ConfigBuilder
static func offlineFirst() -> ConfigBuilder
static func lowMemory() -> ConfigBuilder
static func default() -> ConfigBuilder
```

### NetworkMonitor

```swift
static let shared: NetworkMonitor

// Status
var isReachable: Bool { get }
var isWiFi: Bool { get }
var isCellular: Bool { get }
var isExpensive: Bool { get }
var statusDescription: String { get }

// Callbacks
var onReachabilityChange: ((Bool) -> Void)? { get set }
var onConnectionTypeChange: ((Bool, Bool) -> Void)? { get set }

// Control
func startMonitoring()
func stopMonitoring()
```

### RetryPolicy

```swift
struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let backoffMultiplier: Double
    let maxDelay: TimeInterval

    static let `default`: RetryPolicy  // 3 retries, 1s base, 2x
    static let aggressive: RetryPolicy  // 5 retries, 0.5s base, 1.5x
    static let conservative: RetryPolicy  // 2 retries, 2s base, 3x
    static let none: RetryPolicy  // No retries

    func delay(forAttempt: Int) -> TimeInterval
    func shouldRetry(for error: Error, attempt: Int) -> Bool
}
```

---

## Additional Resources

### 📚 Core Documentation

- **[Architecture Guide](markdown/ARCHITECTURE.md)** - System architecture, diagrams, and design patterns
- **[Configuration Guide](markdown/CONFIGURATION.md)** - Complete guide to configuring ImageDownloader
- **[Migration Guide](markdown/MIGRATION_GUIDE.md)** - Upgrading between versions (v1.x → v2.0 → v2.1)
- **[Usage Examples](markdown/EXAMPLES.md)** - Ready-to-use code examples for common use cases
- **[Roadmap](markdown/ROADMAP.md)** - Future features and development timeline
- **[API Documentation](https://ductranprof99.github.io/Image-Downloader/)** - Full DocC API reference

### 🎯 Quick Example Links

- **Social Media App** - [View Example](markdown/EXAMPLES.md#social-media-app)
- **E-Commerce App** - [View Example](markdown/EXAMPLES.md#e-commerce-app)
- **Progress Tracking (UIKit)** - [View Example](markdown/EXAMPLES.md#progress-tracking-in-uikit)
- **Progress Tracking (SwiftUI)** - [View Example](markdown/EXAMPLES.md#progress-tracking-in-swiftui)
- **Authenticated API** - [View Example](markdown/EXAMPLES.md#authenticated-api)
- **UIImage Direct Loading** - [View Example](markdown/EXAMPLES.md#uiimage-direct-loading)
- **Custom Configuration** - [View Example](markdown/EXAMPLES.md#custom-configuration)

### 🏗️ Architecture & Design

- **System Overview** - [View Architecture](markdown/ARCHITECTURE.md#system-overview)
- **Component Details** - [View Components](markdown/ARCHITECTURE.md#component-details)
- **Data Flow Diagrams** - [View Flow](markdown/ARCHITECTURE.md#data-flow)
- **Design Patterns** - [View Patterns](markdown/ARCHITECTURE.md#design-patterns)
- **Threading Model** - [View Threading](markdown/ARCHITECTURE.md#threading-model)

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Support

- **Documentation**: [https://ductranprof99.github.io/Image-Downloader/](https://ductranprof99.github.io/Image-Downloader/)
- **Issues**: [GitHub Issues](https://github.com/ductranprof99/Image-Downloader/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ductranprof99/Image-Downloader/discussions)

---

**ImageDownloader** - Built for production, designed for performance. 🚀
