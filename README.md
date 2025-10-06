# ImageDownloader

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2013%2B%20%7C%20macOS%2010.15%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A powerful, production-ready Swift image downloading library with advanced caching, async/await support, and full customization.

## ✨ Features

- 🚀 **Modern Swift Concurrency** - Built-in async/await support
- 💾 **Intelligent Caching** - Two-tier memory cache (high/low priority)
- 📦 **Persistent Storage** - Automatic disk caching with customizable compression
- 🎨 **Fully Customizable** - Protocol-based providers for identifiers, paths, and compression
- 🔄 **Objective-C Compatible** - Full bridging for legacy codebases
- ⚡️ **Production Ready** - Battle-tested architecture with comprehensive error handling

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ductranprof99/ImageDownloaderController.git", from: "2.0.0")
]
```

Or add via Xcode: **File → Add Packages**

## 🚀 Quick Start

### Swift (Async/Await)

```swift
import ImageDownloader

// Simple usage
let result = try await ImageDownloaderManager.shared.requestImage(at: imageURL)
imageView.image = result.image

// With UIKit integration
import ImageDownloaderUI

let imageView = AsyncImageView()
imageView.loadImage(from: imageURL)
```

### Objective-C

```objc
@import ImageDownloader;

[[ImageDownloaderManager shared] requestImageAt:imageURL
                                     completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    self.imageView.image = image;
}];
```

## 📚 Documentation

**Full documentation is available in DocC format.**

### Build Documentation

```bash
# In Xcode: Product → Build Documentation
# Or via command line:
xcodebuild docbuild -scheme ImageDownloader -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Quick Links

- **[Getting Started](Sources/ImageDownloader/ImageDownloader.docc/GettingStarted.md)** - Installation and basic usage
- **[Configuration](Sources/ImageDownloader/ImageDownloader.docc/Configuration.md)** - Configure caching and storage
- **[Async/Await](Sources/ImageDownloader/ImageDownloader.docc/AsyncAwait.md)** - Modern Swift concurrency
- **[Customization](Sources/ImageDownloader/ImageDownloader.docc/Customization.md)** - Customize compression and storage
- **[Migration Guide](Sources/ImageDownloader/ImageDownloader.docc/MigrationGuide.md)** - Migrate from v1.x

## 🎯 Key Use Cases

### Save 70% Disk Space with JPEG

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)
ImageDownloaderManager.shared.configure(config)
```

### Organize 10,000+ Images

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: AdaptiveCompressionProvider()
)
ImageDownloaderManager.shared.configure(config)
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│         Public API Layer                    │
│  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Swift Modern    │  │  Objective-C     │  │
│  │ async/await     │  │  Completions     │  │
│  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│     ImageDownloaderManager                  │
│     - Configuration (injectable)            │
│     - async/await + completion APIs         │
└─────────────────────────────────────────────┘
                    ↓
┌──────────────┬──────────────┬──────────────┐
│ CacheAgent   │ NetworkAgent │ StorageAgent │
│ (async)      │ (async)      │ (async)      │
└──────────────┴──────────────┴──────────────┘
```

## 📊 Performance

| Configuration | Disk Usage | Lookup Speed | Best For |
|--------------|-----------|--------------|----------|
| Default (PNG + Flat) | 100% | Good | Small apps |
| JPEG 0.8 + Flat | 30% | Good | Medium apps |
| Adaptive + Domain | 40% | Excellent | **Production** ⭐ |

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation:** Build with Xcode (Product → Build Documentation)
- **Issues:** [GitHub Issues](https://github.com/ductranprof99/ImageDownloaderController/issues)
- **Migration:** [Migration Guide](Sources/ImageDownloader/ImageDownloader.docc/MigrationGuide.md)

---

**ImageDownloader** - Built for production, designed for performance. 🚀
