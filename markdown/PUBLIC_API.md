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
func requestImageAsync(at: URL, priority: ResourcePriority = .low, shouldSaveToStorage: Bool? = nil) async throws -> ImageResult
func forceReloadImageAsync(at: URL, priority: ResourcePriority = .low) async throws -> ImageResult
func requestImageWithProgress(at: URL, priority: ResourcePriority = .low) -> AsyncThrowingStream<ImageLoadingProgress, Error>

// Completion handlers
func requestImage(at: URL, priority: ResourcePriority = .low, shouldSaveToStorage: Bool? = nil, progress: ImageProgressBlock? = nil, completion: ImageCompletionBlock? = nil, caller: AnyObject? = nil)
func forceReloadImage(at: URL, priority: ResourcePriority = .low, completion: ImageCompletionBlock? = nil)

// Cancellation
func cancelRequest(for: URL, caller: AnyObject?)
func cancelAllRequests(for: URL)

// Cache management
func clearLowPriorityCache()
func clearAllCache()
func clearStorage(completion: ((Bool) -> Void)?)
func hardReset()

// Statistics
func cacheSizeHigh() -> Int
func cacheSizeLow() -> Int
func storageSizeBytes() -> UInt64
func activeDownloadsCount() -> Int

// Observers
func addObserver(_ observer: ImageDownloaderObserver)
func removeObserver(_ observer: ImageDownloaderObserver)
```

---

### 2. Configuration

#### Main Configuration Class
```swift
class IDConfiguration: NSObject {
    let network: IDNetworkConfig
    let cache: IDCacheConfig
    let storage: IDStorageConfig
    let enableDebugLogging: Bool

    init(network: IDNetworkConfig = IDNetworkConfig(),
         cache: IDCacheConfig = IDCacheConfig(),
         storage: IDStorageConfig = IDStorageConfig(),
         enableDebugLogging: Bool = false)

    // Static presets
    static let `default`: IDConfiguration
    static let highPerformance: IDConfiguration
    static let lowMemory: IDConfiguration
    static let offlineFirst: IDConfiguration

    // Convenience accessors (read from network/cache/storage configs)
    var maxConcurrentDownloads: Int { get }
    var timeout: TimeInterval { get }
    var retryPolicy: IDRetryPolicy { get }
    var highPriorityLimit: Int { get }
    var lowPriorityLimit: Int { get }
    var shouldSaveToStorage: Bool { get }
}
```

#### Network Configuration
```swift
class IDNetworkConfig: NSObject {
    let maxConcurrentDownloads: Int
    let timeout: TimeInterval
    let allowsCellularAccess: Bool
    let retryPolicy: IDRetryPolicy
    let customHeaders: [String: String]?
    let authenticationHandler: ((inout URLRequest) -> Void)?

    init(maxConcurrentDownloads: Int = 6,
         timeout: TimeInterval = 30,
         allowsCellularAccess: Bool = true,
         retryPolicy: IDRetryPolicy = .defaultPolicy(),
         customHeaders: [String: String]? = nil,
         authenticationHandler: ((inout URLRequest) -> Void)? = nil)
}
```

#### Cache Configuration
```swift
class IDCacheConfig: NSObject {
    let highPriorityLimit: Int
    let lowPriorityLimit: Int
    let clearLowPriorityOnMemoryWarning: Bool
    let clearAllOnMemoryWarning: Bool

    init(highPriorityLimit: Int = 50,
         lowPriorityLimit: Int = 100,
         clearLowPriorityOnMemoryWarning: Bool = true,
         clearAllOnMemoryWarning: Bool = false)
}
```

#### Storage Configuration
```swift
class IDStorageConfig: NSObject {
    let shouldSaveToStorage: Bool
    let storagePath: String?
    let identifierProvider: ResourceIdentifierProvider?
    let pathProvider: StoragePathProvider?
    let compressionProvider: ImageCompressionProvider?

    init(shouldSaveToStorage: Bool = true,
         storagePath: String? = nil,
         identifierProvider: ResourceIdentifierProvider? = nil,
         pathProvider: StoragePathProvider? = nil,
         compressionProvider: ImageCompressionProvider? = nil)
}
```

#### ConfigBuilder (Fluent API)
```swift
class ConfigBuilder {
    // Static factory methods for presets
    static func `default`() -> ConfigBuilder
    static func highPerformance() -> ConfigBuilder
    static func lowMemory() -> ConfigBuilder
    static func offlineFirst() -> ConfigBuilder

    // Network settings
    func maxConcurrentDownloads(_ value: Int) -> ConfigBuilder
    func timeout(_ value: TimeInterval) -> ConfigBuilder
    func allowsCellularAccess(_ value: Bool) -> ConfigBuilder
    func retryPolicy(_ value: RetryPolicy) -> ConfigBuilder  // Uses internal RetryPolicy
    func customHeaders(_ value: [String: String]) -> ConfigBuilder
    func authenticationHandler(_ handler: @escaping (inout URLRequest) -> Void) -> ConfigBuilder

    // Cache settings
    func highPriorityLimit(_ value: Int) -> ConfigBuilder
    func lowPriorityLimit(_ value: Int) -> ConfigBuilder
    func clearLowPriorityOnMemoryWarning(_ value: Bool) -> ConfigBuilder
    func clearAllOnMemoryWarning(_ value: Bool) -> ConfigBuilder

    // Storage settings
    func shouldSaveToStorage(_ value: Bool) -> ConfigBuilder
    func storagePath(_ value: String) -> ConfigBuilder
    func identifierProvider(_ provider: ResourceIdentifierProvider) -> ConfigBuilder
    func pathProvider(_ provider: StoragePathProvider) -> ConfigBuilder
    func compressionProvider(_ provider: ImageCompressionProvider) -> ConfigBuilder

    // Debug
    func enableDebugLogging(_ value: Bool) -> ConfigBuilder

    // Build
    func build() -> IDConfiguration
}
```

#### Usage Examples
```swift
// Static presets (Easiest)
let config = IDConfiguration.highPerformance

// Direct instantiation (Objective-C compatible)
let config = IDConfiguration(
    network: IDNetworkConfig(maxConcurrentDownloads: 8, timeout: 60),
    cache: IDCacheConfig(highPriorityLimit: 100, lowPriorityLimit: 200),
    storage: IDStorageConfig(shouldSaveToStorage: true),
    enableDebugLogging: true
)

// ConfigBuilder from scratch (Fluent)
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .timeout(60)
    .retryPolicy(.aggressive)  // RetryPolicy presets: .default, .aggressive, .conservative, .none
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .build()

// ConfigBuilder from preset (Customize preset)
let config = ConfigBuilder.highPerformance()
    .timeout(120)
    .highPriorityLimit(200)
    .build()
```

---

### 3. UI Extensions

#### UIImageView Extension
```swift
extension UIImageView {
    func setImage(
        with url: URL,
        config: IDConfiguration? = nil,
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

#### SwiftUI
```swift
struct AsyncImageView: View {
    init(url: URL,
         config: IDConfiguration? = nil,
         placeholder: Image? = nil,
         errorImage: Image? = nil,
         priority: ResourcePriority = .low)
}

struct ProgressiveAsyncImage<Content: View, Placeholder: View>: View {
    init(url: URL,
         config: IDConfiguration? = nil,
         priority: ResourcePriority = .low,
         @ViewBuilder content: @escaping (Image, CGFloat) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder)
}
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

#### IDImageResult (Objective-C)
```swift
@objc class IDImageResult: NSObject {
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
    case storageError(Error)
    case unknown(Error)
}
```

#### IDErrorCode (Objective-C)
```swift
@objc enum IDErrorCode: Int {
    case invalidURL
    case networkError
    case timeout
    case cancelled
    case notFound
    case decodingFailed
    case storageError
    case unknown
}
```

#### ResourcePriority
```swift
enum ResourcePriority: Int {
    case high
    case low
}
```

#### IDRetryPolicy (Objective-C)
```swift
@objc class IDRetryPolicy: NSObject {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let backoffMultiplier: Double
    let maxDelay: TimeInterval

    init(maxRetries: Int = 3,
         baseDelay: TimeInterval = 1.0,
         backoffMultiplier: Double = 2.0,
         maxDelay: TimeInterval = 60.0)

    // Static factory methods
    @objc static func defaultPolicy() -> IDRetryPolicy      // 3 retries, 1s base, 2x multiplier
    @objc static func aggressivePolicy() -> IDRetryPolicy   // 5 retries, 0.5s base, 2x multiplier
    @objc static func conservativePolicy() -> IDRetryPolicy // 2 retries, 2s base, 3x multiplier
    @objc static func noRetry() -> IDRetryPolicy            // 0 retries

    // Convert to internal Swift type
    func toSwift() -> RetryPolicy
}
```

#### RetryPolicy (Swift, used by ConfigBuilder)
```swift
struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let backoffMultiplier: Double
    let maxDelay: TimeInterval

    init(maxRetries: Int = 3,
         baseDelay: TimeInterval = 1.0,
         backoffMultiplier: Double = 2.0,
         maxDelay: TimeInterval = 60.0)

    // Static presets
    static let `default`: RetryPolicy      // 3 retries, 1s base, 2x multiplier
    static let aggressive: RetryPolicy     // 5 retries, 0.5s base, 1.5x multiplier
    static let conservative: RetryPolicy   // 2 retries, 2s base, 3x multiplier
    static let none: RetryPolicy           // 0 retries
}
```

**Note:** ConfigBuilder uses `RetryPolicy` (Swift struct), while IDNetworkConfig uses `IDRetryPolicy` (ObjC class). They are automatically converted.

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
// Resize
class ResizeTransformation: ImageTransformation {
    init(targetSize: CGSize, contentMode: UIView.ContentMode = .scaleAspectFill)
}

// Circle
class CircleTransformation: ImageTransformation {
    init(diameter: CGFloat? = nil)  // nil = use image size
}

// Rounded corners
class RoundedCornersTransformation: ImageTransformation {
    init(cornerRadius: CGFloat, targetSize: CGSize? = nil)
}

// Crop
class CropTransformation: ImageTransformation {
    init(cropRect: CGRect)
}

// Aspect ratio
class AspectRatioTransformation: ImageTransformation {
    enum FillMode {
        case fit    // Letterbox
        case fill   // Crop
    }
    init(aspectRatio: CGFloat, fillMode: FillMode = .fit)
}

// Composite (chain multiple)
class CompositeTransformation: ImageTransformation {
    init(transformations: [ImageTransformation])
}
```

#### UIImage Extensions
```swift
extension UIImage {
    func applying(_ transformation: ImageTransformation) -> UIImage?
    func resized(to size: CGSize, contentMode: UIView.ContentMode = .scaleAspectFill) -> UIImage?
    func cropped(to rect: CGRect) -> UIImage?
    func withRoundedCorners(radius: CGFloat, targetSize: CGSize? = nil) -> UIImage?
    func circularImage(diameter: CGFloat? = nil) -> UIImage?
    func withAspectRatio(_ ratio: CGFloat, fillMode: AspectRatioTransformation.FillMode = .fit) -> UIImage?
}
```

---

### 6. Observers

```swift
protocol ImageDownloaderObserver: AnyObject {
    var requiresMainThread: Bool { get }

    // All methods are optional (have default implementations)
    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool)
    func imageDidFail(for url: URL, error: Error)
    func imageDownloadProgress(for url: URL, progress: CGFloat)
    func imageWillStartDownloading(for url: URL)
}
```

---

### 7. Provider Protocols (For Customization)

#### Resource Identifier Provider
```swift
protocol ResourceIdentifierProvider {
    func identifier(for url: URL) -> String
}

// Built-in implementations
class MD5IdentifierProvider: ResourceIdentifierProvider          // Default, backward compatible
class SHA256IdentifierProvider: ResourceIdentifierProvider       // More secure
class DefaultIdentifierProvider: ResourceIdentifierProvider      // Alias for MD5
```

#### Storage Path Provider
```swift
protocol StoragePathProvider {
    func path(for url: URL, identifier: String) -> String
    func directoryStructure(for url: URL) -> [String]
}

// Built-in implementations
class FlatHierarchicalPathProvider: StoragePathProvider          // All files in root (default)
class DomainHierarchicalPathProvider: StoragePathProvider        // Organize by domain (cdn.example.com/abc123.png)
class DateHierarchicalPathProvider: StoragePathProvider          // Organize by date (2025/10/07/abc123.png)
class DefaultHierarchicalPathProvider: StoragePathProvider       // Alias for Flat
```

#### Image Compression Provider
```swift
protocol ImageCompressionProvider {
    func compress(_ image: UIImage) -> Data?
    func decompress(_ data: Data) -> UIImage?
    var fileExtension: String { get }
    var name: String { get }
}

// Built-in implementations
class PNGCompressionProvider: ImageCompressionProvider           // Lossless, default
class JPEGCompressionProvider: ImageCompressionProvider {
    init(quality: CGFloat = 0.8)                                // Lossy, configurable
}
class AdaptiveCompressionProvider: ImageCompressionProvider      // PNG for small, JPEG for large
class DefaultCompressionProvider: ImageCompressionProvider       // Alias for PNG
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
- `CachePriority` - Internal enum (maps from ResourcePriority)
- `NetworkTaskState` - Internal enum
- `CacheAgentDelegate` - Internal protocol
- `NetworkConfig`, `CacheConfig`, `StorageConfig` - Internal structs (wrapped by ID* classes)

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

### With Custom Configuration
```swift
// Use preset
imageView.setImage(with: url, config: IDConfiguration.highPerformance)

// Custom with builder
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .retryPolicy(.aggressive)  // RetryPolicy presets
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .build()

imageView.setImage(with: url, config: config)
```

### Async/Await
```swift
Task {
    let result = try await ImageDownloaderManager.shared.requestImageAsync(at: url)
    imageView.image = result.image
    print("From cache: \(result.fromCache), from storage: \(result.fromStorage)")
}
```

### Custom Storage Providers
```swift
let config = IDStorageConfig(
    shouldSaveToStorage: true,
    identifierProvider: SHA256IdentifierProvider(),
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: JPEGCompressionProvider(quality: 0.9)
)

let fullConfig = IDConfiguration(
    storage: config,
    enableDebugLogging: true
)

let manager = ImageDownloaderManager.instance(for: fullConfig)
```

---

## 🎯 Design Philosophy

1. **Simple by default** - 90% of users use simple API
2. **Customizable when needed** - Protocols for advanced customization
3. **ObjC compatible** - All public types have @objc wrappers
4. **Hide implementation** - Internal agents are not exposed
5. **Robust** - We can refactor internals without breaking your code
6. **Easy to integrate** - Minimal cognitive load

---

## Summary

**Public API Surface:**
- ✅ 1 Manager class (`ImageDownloaderManager`)
- ✅ 4 Config classes (`IDConfiguration`, `IDNetworkConfig`, `IDCacheConfig`, `IDStorageConfig`)
- ✅ 1 Builder class (`ConfigBuilder`)
- ✅ 4 Static presets (`.default`, `.highPerformance`, `.lowMemory`, `.offlineFirst`)
- ✅ UI extensions (UIKit + SwiftUI)
- ✅ 6 Essential types/enums
- ✅ 6 Built-in transformations
- ✅ Observer system
- ✅ 3 Provider protocols with 8 built-in implementations

**Total: ~25 public types** (clean and focused!)

Everything else is internal implementation detail that you don't need to worry about.
