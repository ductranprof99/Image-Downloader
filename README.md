# ImageDownloader - Swift Image Loading Library

A powerful, production-ready iOS image loading library with advanced caching, storage, and multi-framework support.

## Features

**Core Features:**
- Two-tier memory cache (high/low priority)
- Persistent disk storage
- Concurrent download management with priority queuing
- Observer pattern for global notifications
- Progress tracking
- MD5-based resource identification

**Multi-Framework Support:**
- **ImageDownloader** - Core library (framework-agnostic)
- **ImageDownloaderUI** - UIKit/SwiftUI adapter with `AsyncImageView` and convenience views
- **ImageDownloaderComponentKit** - ComponentKit integration
- **ImageDownloaderSwiftUI** - Native SwiftUI support (coming soon)

**Production Ready:**
- Memory-efficient two-tier caching
- Automatic cache cleanup
- Thread-safe operations
- Request deduplication (planned)
- Retry mechanism (planned)

## Installation

### Swift Package Manager

Add ImageDownloader to your project via Xcode:

1. File → Add Packages
2. Enter repository URL
3. Select version/branch
4. Choose targets you need:
   - `ImageDownloader` - Core library (required)
   - `ImageDownloaderUI` - UIKit/SwiftUI support
   - `ImageDownloaderComponentKit` - ComponentKit support

Or add to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/yourorg/ImageDownloader.git", from: "2.0.0")
]
```

## Quick Start

### SwiftUI - Using AsyncImageView

```swift
import ImageDownloaderUI

struct ContentView: View {
    var body: some View {
        AsyncImageView(
            url: URL(string: "https://example.com/image.jpg")!,
            placeholder: Image("placeholder"),
            priority: .high,
            shouldSaveToStorage: true
        )
        .aspectRatio(contentMode: .fill)
        .frame(width: 100, height: 100)
        .clipShape(Circle())
    }
}
```

### SwiftUI - With Progress Tracking

```swift
import ImageDownloaderUI

struct ImageWithProgress: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            AsyncImageView(
                url: URL(string: "https://example.com/image.jpg")!,
                onProgress: { progress in
                    self.progress = progress
                },
                onCompletion: { image, error in
                    if let image = image {
                        print("Image loaded: \(image)")
                    }
                }
            )

            if progress < 1.0 {
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
            }
        }
    }
}
```

### UIKit - Using AsyncImageView

```swift
import ImageDownloaderUI

let imageView = AsyncImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
imageView.placeholderImage = UIImage(named: "placeholder")
imageView.priority = .high
imageView.shouldSaveToStorage = true

// With progress tracking
imageView.onProgress = { progress in
    print("Loading: \(Int(progress * 100))%")
}

// With completion callback
imageView.onCompletion = { image, error, fromCache, fromStorage in
    if let image = image {
        print("Loaded from \(fromCache ? "cache" : "network")")
    }
}

imageView.loadImage(from: URL(string: "https://example.com/image.jpg")!)
```

### UIKit - Using UIImageView Extension

```swift
import ImageDownloaderUI

let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

// Simple usage
imageView.setImage(with: URL(string: "https://example.com/image.jpg")!)

// With placeholder
imageView.setImage(
    with: URL(string: "https://example.com/image.jpg")!,
    placeholder: UIImage(named: "placeholder")
)

// With priority and progress
imageView.setImage(
    with: URL(string: "https://example.com/image.jpg")!,
    placeholder: UIImage(named: "placeholder"),
    priority: .high,
    onProgress: { progress in
        print("Progress: \(Int(progress * 100))%")
    }
)
```

### ComponentKit - Using NetworkImageView

```swift
import ImageDownloaderComponentKit

let imageComponent = NetworkImageView.new(
    url: "https://example.com/image.jpg",
    size: CKComponentSize(
        width: .percent(1),
        height: .points(200)
    ),
    options: NetworkImageOptions(
        placeholder: UIImage(named: "placeholder"),
        maskType: .circle,
        cachePriority: .high,
        shouldSaveToStorage: true,
        progressOverlay: true,
        onProgress: { progress in
            print("Loading: \(Int(progress * 100))%")
        },
        onCompletion: { image, error, fromCache in
            print("Image loaded")
        }
    ),
    attributes: [:]
)
```

### Core API - Direct ImageDownloaderManager Usage

```swift
import ImageDownloader

ImageDownloaderManager.shared.requestImage(
    at: URL(string: "https://example.com/image.jpg")!,
    priority: .high,
    shouldSaveToStorage: true,
    progress: { progress in
        print("Progress: \(Int(progress * 100))%")
    },
    completion: { image, error, fromCache, fromStorage in
        if let image = image {
            let source = fromCache ? "cache" : (fromStorage ? "storage" : "network")
            print("Got image from \(source)")
        }
    },
    caller: self
)
```

## Configuration

### Global Configuration

```swift
ImageDownloaderManager.shared.configure(
    maxConcurrentDownloads: 6,
    highCachePriority: 100,
    lowCachePriority: 200,
    storagePath: nil  // nil = default Documents directory
)
```

### Cache Management

```swift
// Clear low priority cache only
ImageDownloaderManager.shared.clearLowPriorityCache()

// Clear all memory cache
ImageDownloaderManager.shared.clearAllCache()

// Clear disk storage
ImageDownloaderManager.shared.clearStorage { success in
    print("Storage cleared: \(success)")
}

// Hard reset (clear everything)
ImageDownloaderManager.shared.hardReset()
```

### Statistics

```swift
let highCacheCount = ImageDownloaderManager.shared.cacheSizeHigh()
let lowCacheCount = ImageDownloaderManager.shared.cacheSizeLow()
let storageBytes = ImageDownloaderManager.shared.storageSizeBytes()
let activeDownloads = ImageDownloaderManager.shared.activeDownloadsCount()
let queuedDownloads = ImageDownloaderManager.shared.queuedDownloadsCount()

print("Cache: \(highCacheCount) high, \(lowCacheCount) low | Storage: \(storageBytes) bytes | Downloads: \(activeDownloads) active, \(queuedDownloads) queued")
```

## Observer Pattern

Observe global image loading events:

```swift
import ImageDownloader

class MyObserver: ImageDownloaderObserver {
    func imageDidStartLoading(_ url: URL) {
        print("Started loading: \(url)")
    }

    func imageDidFinishLoading(
        _ url: URL,
        image: UIImage,
        fromCache: Bool,
        fromStorage: Bool
    ) {
        print("Finished loading: \(url) (from \(fromCache ? "cache" : "network"))")
    }

    func imageDidFailLoading(_ url: URL, error: Error) {
        print("Failed loading: \(url) - \(error.localizedDescription)")
    }
}

// Register observer
let observer = MyObserver()
ImageDownloaderManager.shared.addObserver(observer)

// Unregister when done
ImageDownloaderManager.shared.removeObserver(observer)
```

## Architecture

### ImageDownloader Core

```
ImageDownloaderManager (Coordinator)
├── CacheAgent (Two-tier memory cache)
├── StorageAgent (Disk persistence)
├── NetworkAgent (Concurrent downloads)
└── Observer (Event notifications)
```

### Adapters

- **ImageDownloaderUI**: `AsyncImageView` + `UIImageView` extension
- **ImageDownloaderComponentKit**: `NetworkImageView` + `ComponentImageDownloader`
- **ImageDownloaderSwiftUI**: Native SwiftUI views (planned)

## Roadmap

### Version 2.1.0
- [ ] Protocol-based multi-framework adapter system
- [ ] Configuration inheritance (global → request → runtime)
- [ ] Request deduplication

### Version 2.2.0
- [ ] Retry mechanism with exponential backoff
- [ ] Custom headers/authentication support
- [ ] Bandwidth throttling
- [ ] Progressive image loading
- [ ] WebP/AVIF format support

### Version 2.3.0
- [ ] Enhanced SwiftUI adapter
- [ ] Network reachability monitoring
- [ ] Request interceptor pattern

## Requirements

- iOS 13.0+
- macOS 10.15+
- Xcode 14.0+
- Swift 5.9+

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.

## Support

- Documentation: See `/docs` directory
- Issues: GitHub Issues
- Discussions: GitHub Discussions

---

**ImageDownloader** - Built for production, designed for performance.
