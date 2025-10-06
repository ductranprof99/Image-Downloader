# ImageDownloader Usage Guide

Complete guide for using the ImageDownloader library with both Swift (async/await) and Objective-C.

## Table of Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Swift API (Async/Await)](#swift-api-asyncawait)
- [Swift API (Completion Handlers)](#swift-api-completion-handlers)
- [Objective-C API](#objective-c-api)
- [UI Integration](#ui-integration)
- [Advanced Features](#advanced-features)

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/ImageDownloader.git", from: "2.0.0")
]
```

Or add via Xcode:
1. File → Add Packages
2. Enter repository URL
3. Choose modules:
   - `ImageDownloader` - Core library (required)
   - `ImageDownloaderUI` - UIKit support

---

## Quick Start

### Swift (Modern async/await)

```swift
import ImageDownloader

// Simple usage
let result = try await ImageDownloaderManager.shared.requestImage(at: imageURL)
imageView.image = result.image
print("From cache: \(result.fromCache)")
```

### Objective-C

```objc
@import ImageDownloader;

[[ImageDownloaderManager shared] requestImageAt:imageURL completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (image) {
        self.imageView.image = image;
    }
}];
```

---

## Configuration

The library supports both global and request-level configuration.

### Global Configuration (Swift)

```swift
import ImageDownloader

// Use predefined configurations
ImageDownloaderManager.shared.configure(.default)
ImageDownloaderManager.shared.configure(.highPerformance)
ImageDownloaderManager.shared.configure(.lowMemory)

// Custom configuration
let config = ImageDownloaderConfiguration(
    maxConcurrentDownloads: 6,
    timeout: 30,
    highCachePriority: 100,
    lowCachePriority: 200,
    storagePath: nil,  // nil = default cache directory
    shouldSaveToStorage: true,
    enableDebugLogging: false,
    enableRetry: true,
    retryAttempts: 3
)

ImageDownloaderManager.shared.configure(config)

// Access current configuration
let currentConfig = ImageDownloaderManager.shared.configuration
print("Max concurrent: \(currentConfig.maxConcurrentDownloads)")
```

### Global Configuration (Objective-C)

```objc
@import ImageDownloader;

// Use predefined configurations
[[ImageDownloaderManager shared] configure:[IDConfiguration defaultConfiguration]];
[[ImageDownloaderManager shared] configure:[IDConfiguration highPerformanceConfiguration]];
[[ImageDownloaderManager shared] configure:[IDConfiguration lowMemoryConfiguration]];

// Custom configuration
IDConfiguration *config = [[IDConfiguration alloc] init];
config.maxConcurrentDownloads = 6;
config.timeout = 30;
config.highCachePriority = 100;
config.lowCachePriority = 200;
config.shouldSaveToStorage = YES;
config.enableDebugLogging = NO;
config.enableRetry = YES;
config.retryAttempts = 3;

[[ImageDownloaderManager shared] configure:config];
```

---

## Swift API (Async/Await)

### Basic Image Request

```swift
import ImageDownloader

func loadImage() async {
    do {
        let result = try await ImageDownloaderManager.shared.requestImage(at: url)
        imageView.image = result.image

        // Check source
        if result.fromCache {
            print("Loaded from memory cache")
        } else if result.fromStorage {
            print("Loaded from disk storage")
        } else {
            print("Downloaded from network")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

### With Priority and Progress

```swift
func loadImageWithProgress() async {
    do {
        let result = try await ImageDownloaderManager.shared.requestImage(
            at: url,
            priority: .high,
            shouldSaveToStorage: true,
            progress: { progress in
                print("Download progress: \(Int(progress * 100))%")
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.progressView.progress = Float(progress)
                }
            }
        )

        imageView.image = result.image
    } catch let error as ImageDownloaderError {
        switch error {
        case .invalidURL:
            print("Invalid URL")
        case .networkError(let underlyingError):
            print("Network error: \(underlyingError)")
        case .decodingFailed:
            print("Failed to decode image")
        case .cancelled:
            print("Download cancelled")
        case .timeout:
            print("Request timed out")
        case .notFound:
            print("Image not found")
        case .unknown(let underlyingError):
            print("Unknown error: \(underlyingError)")
        }
    }
}
```

### Force Reload (Bypass Cache)

```swift
func forceReloadImage() async {
    do {
        let result = try await ImageDownloaderManager.shared.forceReloadImage(
            at: url,
            priority: .high
        )
        imageView.image = result.image
    } catch {
        print("Error: \(error)")
    }
}
```

### With Task and Cancellation

```swift
class MyViewController: UIViewController {
    private var downloadTask: Task<Void, Never>?

    func startDownload() {
        downloadTask = Task {
            do {
                let result = try await ImageDownloaderManager.shared.requestImage(at: url)
                imageView.image = result.image
            } catch is CancellationError {
                print("Download was cancelled")
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
    }
}
```

---

## Swift API (Completion Handlers)

### Basic Usage

```swift
import ImageDownloader

ImageDownloaderManager.shared.requestImage(at: url) { image, error, fromCache, fromStorage in
    if let image = image {
        self.imageView.image = image
        print("Source: \(fromCache ? "cache" : fromStorage ? "storage" : "network")")
    } else if let error = error {
        print("Error: \(error.localizedDescription)")
    }
}
```

### With Progress

```swift
ImageDownloaderManager.shared.requestImage(
    at: url,
    priority: .high,
    shouldSaveToStorage: true,
    progress: { progress in
        print("Progress: \(Int(progress * 100))%")
    },
    completion: { image, error, fromCache, fromStorage in
        if let image = image {
            self.imageView.image = image
        }
    },
    caller: self
)
```

### Cancellation

```swift
// Cancel specific request
ImageDownloaderManager.shared.cancelRequest(for: url, caller: self)

// Cancel all requests for a URL
ImageDownloaderManager.shared.cancelAllRequests(for: url)
```

---

## Objective-C API

### Basic Usage

```objc
@import ImageDownloader;

[[ImageDownloaderManager shared] requestImageAt:url
                                     completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (image) {
        self.imageView.image = image;
        NSLog(@"Source: %@", fromCache ? @"cache" : fromStorage ? @"storage" : @"network");
    } else if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}];
```

### With Priority and Progress

```objc
[[ImageDownloaderManager shared] requestImageAt:url
                                       priority:1  // 0 = low, 1 = high
                            shouldSaveToStorage:YES
                                       progress:^(CGFloat progress) {
    NSLog(@"Progress: %.0f%%", progress * 100);
}
                                     completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (image) {
        self.imageView.image = image;
    }
}
                                         caller:self];
```

### Error Handling

```objc
[[ImageDownloaderManager shared] requestImageAt:url
                                     completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (error) {
        switch (error.code) {
            case IDErrorCodeInvalidURL:
                NSLog(@"Invalid URL");
                break;
            case IDErrorCodeNetworkError:
                NSLog(@"Network error: %@", error.userInfo[NSUnderlyingErrorKey]);
                break;
            case IDErrorCodeDecodingFailed:
                NSLog(@"Failed to decode image");
                break;
            case IDErrorCodeCancelled:
                NSLog(@"Download cancelled");
                break;
            case IDErrorCodeTimeout:
                NSLog(@"Request timed out");
                break;
            case IDErrorCodeNotFound:
                NSLog(@"Image not found");
                break;
            default:
                NSLog(@"Unknown error: %@", error.localizedDescription);
                break;
        }
    } else if (image) {
        self.imageView.image = image;
    }
}];
```

### Cancellation

```objc
// Cancel specific request
[[ImageDownloaderManager shared] cancelRequestFor:url caller:self];

// Cancel all requests for a URL
[[ImageDownloaderManager shared] cancelAllRequestsFor:url];
```

---

## UI Integration

### UIKit - AsyncImageView (Swift)

```swift
import ImageDownloaderUI

let imageView = AsyncImageView()
imageView.placeholderImage = UIImage(named: "placeholder")
imageView.priority = .high
imageView.shouldSaveToStorage = true

imageView.onProgress = { progress in
    print("Loading: \(Int(progress * 100))%")
}

imageView.onCompletion = { image, error, fromCache, fromStorage in
    if let image = image {
        print("Image loaded!")
    }
}

imageView.loadImage(from: url)
```

### UIKit - UIImageView Extension (Swift)

```swift
import ImageDownloaderUI

// Simple
imageView.setImage(with: url)

// With placeholder
imageView.setImage(with: url, placeholder: UIImage(named: "placeholder"))

// With options
imageView.setImage(
    with: url,
    placeholder: UIImage(named: "placeholder"),
    priority: .high,
    onProgress: { progress in
        print("Progress: \(progress)")
    },
    completion: { result in
        switch result {
        case .success(let image):
            print("Loaded: \(image)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
)

// Cancel
imageView.cancelImageLoading()
```

### UIKit - Objective-C

```objc
@import ImageDownloaderUI;

AsyncImageView *imageView = [[AsyncImageView alloc] init];
imageView.placeholderImage = [UIImage imageNamed:@"placeholder"];
imageView.priority = ResourcePriorityHigh;
imageView.shouldSaveToStorage = YES;

imageView.onProgress = ^(CGFloat progress) {
    NSLog(@"Loading: %.0f%%", progress * 100);
};

imageView.onCompletion = ^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (image) {
        NSLog(@"Image loaded!");
    }
};

[imageView loadImageFrom:url];
```

---

## Advanced Features

### Cache Management

```swift
// Clear low priority cache
ImageDownloaderManager.shared.clearLowPriorityCache()

// Clear all cache
ImageDownloaderManager.shared.clearAllCache()

// Clear storage
ImageDownloaderManager.shared.clearStorage { success in
    print("Storage cleared: \(success)")
}

// Hard reset (everything)
ImageDownloaderManager.shared.hardReset()
```

### Statistics

```swift
let highCacheCount = ImageDownloaderManager.shared.cacheSizeHigh()
let lowCacheCount = ImageDownloaderManager.shared.cacheSizeLow()
let storageBytes = ImageDownloaderManager.shared.storageSizeBytes()
let activeDownloads = ImageDownloaderManager.shared.activeDownloadsCount()
let queuedDownloads = ImageDownloaderManager.shared.queuedDownloadsCount()

print("Cache: \(highCacheCount) high, \(lowCacheCount) low")
print("Storage: \(storageBytes) bytes")
print("Downloads: \(activeDownloads) active, \(queuedDownloads) queued")
```

### Observer Pattern

```swift
import ImageDownloader

class MyObserver: ImageDownloaderObserver {
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool) {
        print("Image loaded: \(url)")
    }

    func imageDidFail(for url: URL, error: Error) {
        print("Image failed: \(url) - \(error)")
    }

    func imageDownloadProgress(for url: URL, progress: CGFloat) {
        print("Progress: \(url) - \(Int(progress * 100))%")
    }

    func imageWillStartDownloading(for url: URL) {
        print("Starting download: \(url)")
    }
}

// Register observer
let observer = MyObserver()
ImageDownloaderManager.shared.addObserver(observer)

// Unregister
ImageDownloaderManager.shared.removeObserver(observer)
```

---

## Best Practices

### 1. Use Async/Await (Swift)
```swift
// ✅ Preferred
Task {
    let result = try await manager.requestImage(at: url)
    imageView.image = result.image
}

// ⚠️ Use only for Objective-C compatibility
manager.requestImage(at: url) { image, error, _, _ in
    imageView.image = image
}
```

### 2. Configure Once at App Launch
```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Configure ImageDownloader once
        ImageDownloaderManager.shared.configure(.highPerformance)

        return true
    }
}
```

### 3. Handle Errors Properly
```swift
do {
    let result = try await manager.requestImage(at: url)
    imageView.image = result.image
} catch let error as ImageDownloaderError {
    // Handle specific errors
    handleError(error)
} catch {
    // Handle unexpected errors
    print("Unexpected error: \(error)")
}
```

### 4. Cancel Unused Downloads
```swift
class MyViewController: UIViewController {
    private var downloadTask: Task<Void, Never>?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        downloadTask?.cancel()
    }
}
```

---

## Platform Support

- **iOS**: 13.0+
- **macOS**: 10.15+
- **Swift**: 5.9+
- **Xcode**: 14.0+

---

## License

MIT License - See LICENSE file for details
