# ImageDownloader

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2013%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.1.0-green.svg)](https://github.com/ductranprof99/Image-Downloader)

A powerful, production-ready Swift image downloading library with advanced caching, async/await support, and clean API.

## ✨ What's New in v0.3.0

- ✅ **Configurable retry logging** - No more spam, debug when needed
- ✅ **Placeholder & error images** - Separate images for loading/error states
- ✅ **Pure async/await API** - No DispatchQueue mixing
- ✅ **Image transformations** - Resize, crop, circle, rounded corners
- ✅ **Background task support** - Downloads continue in background
- ✅ **Automatic cancellation** - SwiftUI & UIKit cell reuse handled
- ✅ **Clean public API** - Only ~20 public types (agents are internal)

## ✨ Features

- 🚀 **Modern Swift Concurrency** - Pure async/await support
- 💾 **Intelligent Caching** - Two-tier memory cache (high/low priority)
- 📦 **Persistent Storage** - Automatic disk caching with customizable compression
- 🎨 **Image Transformations** - Resize, crop, circle, rounded corners (NEW!)
- 🔁 **Smart Retry** - Configurable retry with exponential backoff
- 🔗 **Request Deduplication** - Prevents duplicate concurrent requests
- 🔐 **Custom Headers & Auth** - Add auth tokens, API keys
- 🔄 **Automatic Cancellation** - UIKit cell reuse & SwiftUI lifecycle (NEW!)
- ⚡️ **Production Ready** - Clean API, thread-safe, well-tested

## 🚀 Quick Start

### Installation

```swift
dependencies: [
    .package(url: "https://github.com/ductranprof99/Image-Downloader.git", from: "2.1.0")
]
```

### Basic Usage

```swift
import ImageDownloader

// UIImageView extension (simple)
imageView.setImage(with: url, placeholder: placeholderImage)

// With error image
imageView.setImage(
    with: url,
    placeholder: UIImage(named: "loading"),
    errorImage: UIImage(named: "error")
)

// With transformation
imageView.setImage(
    with: url,
    placeholder: placeholder,
    transformation: CircleTransformation(diameter: 80)
)

// Async/await
let result = try await ImageDownloaderManager.shared.requestImageAsync(at: url)
imageView.image = result.image
```

### With Custom Configuration

```swift
// Use preset configuration
let manager = ImageDownloaderManager.instance(for: IDConfiguration.highPerformance)
let result = try await manager.requestImageAsync(at: imageURL)

// Or build custom config
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .retryPolicy(.aggressive)
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .build()

let manager = ImageDownloaderManager.instance(for: config)
let result = try await manager.requestImageAsync(at: imageURL)
```

## 📚 Documentation

Full documentation lives in the markdown folder.

Quick links:
- [Quick Start](markdown/EXAMPLES.md#basic-usage)
- [Injectable Configuration](markdown/PUBLIC_API.md#2-configuration)
- [Network Features](markdown/EXAMPLES.md#custom-network-config)
- [Advanced Usage](markdown/EXAMPLES.md#asyncawait-usage)
- [API Reference](markdown/PUBLIC_API.md)
- [Examples](markdown/EXAMPLES.md)

### Build DocC Documentation

```bash
# In Xcode: Product → Build Documentation
# Or via command line:
xcodebuild docbuild -scheme ImageDownloader -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 🎯 Key Use Cases

### Save 70% Disk Space with JPEG

```swift
let config = ConfigBuilder()
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .build()

let image = try await UIImage.load(from: url, config: config)
```

### Offline-First App

```swift
// Use preset offline-first configuration
let manager = ImageDownloaderManager.instance(for: IDConfiguration.offlineFirst)
let result = try await manager.requestImageAsync(at: url)

// Or customize with builder
let config = ConfigBuilder.offlineFirst()
    .highPriorityLimit(200)
    .lowPriorityLimit(500)
    .build()

let manager = ImageDownloaderManager.instance(for: config)
let result = try await manager.requestImageAsync(at: url)
```

### High-Performance Feed

```swift
// Use preset high-performance configuration
imageView.setImage(with: url, config: IDConfiguration.highPerformance)

// Or build custom high-performance config
let config = ConfigBuilder.highPerformance()
    .maxConcurrentDownloads(10)
    .build()

imageView.setImage(with: url, config: config)
```

## 🆕 What's New in v2.1

### Injectable Configuration
Different configs for different use cases:

```swift
// Avatars: fast, high priority
let avatarManager = ImageDownloaderManager.instance(for: IDConfiguration.highPerformance)
let avatar = try await avatarManager.requestImageAsync(at: avatarURL, priority: .high)

// Photos: offline-first, huge cache
let photoManager = ImageDownloaderManager.instance(for: IDConfiguration.offlineFirst)
let photo = try await photoManager.requestImageAsync(at: photoURL)
```

### Retry with Exponential Backoff
Automatic retry for failed downloads:

```swift
let config = ConfigBuilder()
    .retryPolicy(.aggressive)  // 5 retries, 0.5s base
    .build()
```

### Request Deduplication
Saves 50-90% bandwidth in list/grid views - multiple requests for the same URL are automatically merged.

### Custom Headers & Authentication

```swift
let config = ConfigBuilder()
    .customHeaders(["User-Agent": "MyApp/1.0"])
    .authenticationHandler { request in
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .build()
```

### Network Reachability Monitoring

```swift
NetworkMonitor.shared.startMonitoring()
NetworkMonitor.shared.onReachabilityChange = { isReachable in
    print("Network: \(isReachable)")
}
```

## 📊 Performance

| Configuration | Disk Usage | Lookup Speed | Best For |
|--------------|-----------|--------------|----------|
| Default (PNG + Flat) | 100% | Good | Small apps |
| JPEG 0.8 + Flat | 30% | Good | Medium apps |
| Adaptive + Domain | 40% | Excellent | **Production** ⭐ |

## 🗺️ Roadmap

See [markdown/ROADMAP.md](markdown/ROADMAP.md) for detailed roadmap.

**v2.1.0** ✅ (Current)
- Injectable configuration system
- Retry with exponential backoff
- Request deduplication
- Custom headers & authentication
- Network reachability monitoring

**v2.2.0** (Q2 2025)
- Enhanced storage with inspection API
- Bandwidth throttling
- Request interceptor pattern

**v3.0.0** (Q4 2025)
- Actor-based concurrency
- Combine framework integration
- SwiftUI native components

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Public API**: [markdown/PUBLIC_API.md](markdown/PUBLIC_API.md)
- **Architecture**: [markdown/ARCHITECTURE.md](markdown/ARCHITECTURE.md)
- **Examples**: [markdown/EXAMPLES.md](markdown/EXAMPLES.md)
- **Roadmap**: [markdown/ROADMAP.md](markdown/ROADMAP.md)
- **DocC Documentation**: [https://ductranprof99.github.io/Image-Downloader/](https://ductranprof99.github.io/Image-Downloader/)
- **Issues**: [GitHub Issues](https://github.com/ductranprof99/Image-Downloader/issues)

---

**ImageDownloader** - Built for production, designed for performance. 🚀

---

## 📚 Documentation

Complete documentation in the [markdown/](markdown/) folder:

- **[ARCHITECTURE.md](markdown/ARCHITECTURE.md)** - Architecture with diagrams, threading model, design patterns
- **[EXAMPLES.md](markdown/EXAMPLES.md)** - Code examples, patterns, cancellation, transformations
- **[PUBLIC_API.md](markdown/PUBLIC_API.md)** - Complete API reference, what's public/internal
- **[ROADMAP.md](markdown/ROADMAP.md)** - Future improvements and planned features

---

## 💡 Design Philosophy

- **Simple by default** - 90% of users need simple API
- **Customizable when needed** - Protocols for advanced customization
- **Clean API** - Implementation details are internal (~20 public types)
- **Production ready** - Thread-safe, well-tested, robust

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
