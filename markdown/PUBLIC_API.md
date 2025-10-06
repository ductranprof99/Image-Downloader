# ImageDownloader - Public API Reference

## Overview

This library has a **minimal public API** - you only see what you need. Implementation details are internal.

---

## 🎯 Public API (What You Can Use)

### 1. Main Manager

```swift
ImageDownloaderManager.shared  // Singleton

// Or custom instance
let manager = ImageDownloaderManager.instance(for: myConfig)
```

**Methods:**
```swift
// Async/await
func requestImageAsync(at: URL) async throws -> ImageResult
func forceReloadImageAsync(at: URL) async throws -> ImageResult
func requestImageWithProgress(at: URL) -> AsyncThrowingStream<ImageLoadingProgress, Error>

// Completion handlers
func requestImage(at: URL, completion: ImageCompletionBlock?)
func forceReloadImage(at: URL, completion: ImageCompletionBlock?)

// Cancellation
func cancelRequest(for: URL, caller: AnyObject?)
func cancelAllRequests(for: URL)

// Cache management
func clearLowPriorityCache()
func clearAllCache()
func clearStorage(completion: ((Bool) -> Void)?)
func hardReset()

// Observers
func addObserver(_ observer: ImageDownloaderObserver)
func removeObserver(_ observer: ImageDownloaderObserver)
```

---

### 2. Configuration

#### Simple Configuration
```swift
struct ImageDownloaderConfiguration {
    var maxConcurrentDownloads: Int
    var timeout: TimeInterval
    var retryPolicy: RetryPolicy
    var shouldSaveToStorage: Bool
    // ... more options
}

ImageDownloaderManager.shared.configure(config)
```

#### Protocol-Based (Advanced)
```swift
protocol ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol { get }
    var cacheConfig: CacheConfigProtocol { get }
    var storageConfig: StorageConfigProtocol { get }
}

protocol NetworkConfigProtocol {
    var maxConcurrentDownloads: Int { get }
    var timeout: TimeInterval { get }
    var retryPolicy: RetryPolicy { get }
    // ...
}

protocol CacheConfigProtocol {
    var highPriorityLimit: Int { get }
    var lowPriorityLimit: Int { get }
}

protocol StorageConfigProtocol {
    var storagePath: String? { get }
    var shouldSaveToStorage: Bool { get }
    var identifierProvider: ResourceIdentifierProvider { get }
    // ...
}
```

#### Presets (Easy to Use)
```swift
FastConfig()           // Fast, high concurrency
OfflineFirstConfig()   // Prefers cache/storage
LowMemoryConfig()      // Low memory footprint
```

---

### 3. UI Extensions

#### UIImageView Extension
```swift
extension UIImageView {
    func setImage(
        with url: URL,
        placeholder: UIImage? = nil,
        errorImage: UIImage? = nil,
        priority: ResourcePriority = .low,
        transformation: ImageTransformation? = nil,
        onProgress: ((CGFloat) -> Void)? = nil,
        onCompletion: ImageCompletionBlock? = nil
    )

    func cancelImageLoading()
}
```

#### UIAsyncImageView (Subclass)
```swift
class UIAsyncImageView: UIImageView {
    var placeholderImage: UIImage?
    var errorImage: UIImage?
    var priority: ResourcePriority
    var shouldSaveToStorage: Bool

    func loadImage(from url: URL)
    func cancelLoading()
}
```

#### SwiftUI
```swift
AsyncImageView(
    url: URL,
    placeholder: Image? = nil,
    errorImage: Image? = nil,
    priority: ResourcePriority = .low
)

ProgressiveAsyncImage(
    url: URL,
    content: (Image, CGFloat) -> Content,
    placeholder: () -> Placeholder
)
```

---

### 4. Essential Types

#### ImageResult
```swift
struct ImageResult {
    let image: UIImage
    let url: URL
    let fromCache: Bool
    let fromStorage: Bool
}
```

#### ImageDownloaderError
```swift
enum ImageDownloaderError: Error {
    case invalidURL
    case networkError(Error)
    case timeout
    case cancelled
    case notFound
    case decodingFailed
    case unknown(Error)
}
```

#### ResourcePriority
```swift
enum ResourcePriority {
    case high
    case low
}
```

#### RetryPolicy
```swift
struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let backoffMultiplier: Double
    let maxDelay: TimeInterval
    let enableLogging: Bool

    static let `default`: RetryPolicy
    static let aggressive: RetryPolicy
    static let conservative: RetryPolicy
    static let none: RetryPolicy
}
```

---

### 5. Image Transformations

#### Protocol
```swift
protocol ImageTransformation {
    func transform(_ image: UIImage) -> UIImage?
    var identifier: String { get }
}
```

#### Built-in Transformations
```swift
ResizeTransformation(targetSize: CGSize, contentMode: UIView.ContentMode)
CircleTransformation(diameter: CGFloat?)
RoundedCornersTransformation(cornerRadius: CGFloat, targetSize: CGSize?)
CropTransformation(cropRect: CGRect)
AspectRatioTransformation(aspectRatio: CGFloat, fillMode: FillMode)
CompositeTransformation(transformations: [ImageTransformation])
```

#### UIImage Extensions
```swift
extension UIImage {
    func applying(_ transformation: ImageTransformation) -> UIImage?
    func resized(to size: CGSize, contentMode: UIView.ContentMode) -> UIImage?
    func cropped(to rect: CGRect) -> UIImage?
    func withRoundedCorners(radius: CGFloat, targetSize: CGSize?) -> UIImage?
    func circularImage(diameter: CGFloat?) -> UIImage?
    func withAspectRatio(_ ratio: CGFloat, fillMode: AspectRatioTransformation.FillMode) -> UIImage?
}
```

---

### 6. Observers

```swift
protocol ImageDownloaderObserver: AnyObject {
    var requiresMainThread: Bool { get }
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool)
    func imageDidFail(for url: URL, error: Error)
    func imageDownloadProgress(for url: URL, progress: CGFloat)
    func imageWillStartDownloading(for url: URL)
}
```

---

### 7. Provider Protocols (For Customization)

```swift
protocol ResourceIdentifierProvider {
    func identifier(for url: URL) -> String
}

protocol StoragePathProvider {
    func path(for identifier: String) -> String
}

protocol ImageCompressionProvider {
    func compress(_ image: UIImage) -> Data?
    func decompress(_ data: Data) -> UIImage?
}
```

---

## ❌ What's NOT Public (Internal Implementation)

These are implementation details you don't need to know about:

- `NetworkAgent` - Network handling
- `CacheAgent` - Memory cache
- `StorageAgent` - Disk storage
- `NetworkTask`, `NetworkQueue` - Task management
- `RequestDeduplicator` - Deduplication logic
- `BackgroundTaskManager` - Background tasks
- `ResourceModel` - Internal state
- `CachePriority` - Internal enum
- `NetworkTaskState` - Internal enum
- `CacheAgentDelegate` - Internal protocol

---

## 📖 Usage Examples

### Basic (90% of users)
```swift
// Simplest
imageView.setImage(with: url)

// With placeholder
imageView.setImage(with: url, placeholder: UIImage(named: "placeholder"))

// With error image
imageView.setImage(
    with: url,
    placeholder: UIImage(named: "loading"),
    errorImage: UIImage(named: "error")
)
```

### With Transformation
```swift
imageView.setImage(
    with: url,
    placeholder: placeholder,
    transformation: CircleTransformation(diameter: 80)
)
```

### Custom Configuration (Advanced)
```swift
// Create custom config
struct MyConfig: ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol = MyNetworkConfig()
    var cacheConfig: CacheConfigProtocol = DefaultCacheConfig()
    var storageConfig: StorageConfigProtocol = DefaultStorageConfig()
}

struct MyNetworkConfig: NetworkConfigProtocol {
    var maxConcurrentDownloads: Int = 10
    var timeout: TimeInterval = 30
    var retryPolicy: RetryPolicy = RetryPolicy(
        maxRetries: 5,
        baseDelay: 1.0,
        enableLogging: true
    )
    // ... implement other required properties
}

// Use it
let manager = ImageDownloaderManager.instance(for: MyConfig())
imageView.setImage(with: url, config: MyConfig())
```

### Async/Await
```swift
Task {
    let result = try await ImageDownloaderManager.shared.requestImageAsync(at: url)
    imageView.image = result.image
}
```

---

## 🎯 Design Philosophy

1. **Simple by default** - 90% of users use simple API
2. **Customizable when needed** - 10% of users use protocols for customization
3. **Hide implementation** - You don't see internal classes/agents
4. **Robust** - We can refactor internals without breaking your code
5. **Easy to integrate** - Minimal cognitive load

---

## Summary

**Public API Surface:**
- ✅ 1 Manager class
- ✅ 4 Config protocols (customizable)
- ✅ 3 Preset configs (easy)
- ✅ UI extensions (UIKit + SwiftUI)
- ✅ 5 Essential types/enums
- ✅ Transformation system
- ✅ Observer system
- ✅ 3 Provider protocols (for customization)

**Total: ~20 public types** (clean and focused!)

Everything else is internal implementation detail that you don't need to worry about.
