# ImageDownloader - Architecture

Complete architecture overview with diagrams and design patterns.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Component Details](#component-details)
4. [Data Flow](#data-flow)
5. [Design Patterns](#design-patterns)
6. [Threading Model](#threading-model)
7. [Memory Management](#memory-management)
8. [Performance Optimizations](#performance-optimizations)

---

## System Overview

ImageDownloader uses a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                     Client Layer                        │
│  UIImageView, UIImage, SwiftUI, Manager API             │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              ImageDownloaderManager                     │
│  (Coordinator, Request Routing, Observer Management)    │
└─────┬──────────────┬──────────────┬─────────────────────┘
      │              │              │
┌─────▼─────┐  ┌─────▼──────┐  ┌────▼────────┐
│CacheAgent │  │NetworkAgent│  │StorageAgent │
│(Memory)   │  │(Downloads) │  │(Disk)       │
└───────────┘  └────────────┘  └─────────────┘
      │              │              │
      └──────────┬───┴──────────────┘
                 │
           ┌─────▼───────┐
           │ResourceModel│
           │(State Mgmt) │
           └─────────────┘
```

---

## Architecture Diagram

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                │
│  │ UIImageView  │  │   UIImage    │  │   SwiftUI    │                │
│  │  Extension   │  │  Extension   │  │  AsyncImage  │                │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                │
│         │                 │                 │                        │
│         └─────────────────┴─────────────────┘                        │
└─────────────────────────────┬────────────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────────────┐
│                    MANAGER LAYER                                     │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │           ImageDownloaderManager (Singleton)                   │  │
│  │  • Request routing                                             │  │
│  │  • Configuration management                                    │  │
│  │  • Observer pattern coordination                               │  │
│  │  • Request deduplication                                       │  │
│  │  • Priority queue management                                   │  │
│  └─────────┬──────────────────┬────────────────┬──────────────────┘  │
└────────────┼──────────────────┼────────────────┼─────────────────────┘
             │                  │                │
┌────────────▼──────┐  ┌────────▼───────┐  ┌────▼─────────────┐
│   CacheAgent      │  │ NetworkAgent   │  │  StorageAgent    │
│                   │  │                │  │                  │
│ • Memory cache    │  │ • URLSession   │  │ • FileManager    │
│ • High priority   │  │ • Download     │  │ • Compression    │
│ • Low priority    │  │   queue        │  │ • Path providers │
│ • LRU eviction    │  │ • Retry logic  │  │ • Persistence    │
│ • Fast lookup     │  │ • Progress     │  │ • Storage mgmt   │
└───────────────────┘  └────────────────┘  └──────────────────┘
      │                      │                    │
      └──────────────────────┼────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  ResourceModel   │
                    │                  │
                    │ • State tracking │
                    │ • MD5 identifier │
                    │ • Metadata       │
                    │ • Access time    │
                    └──────────────────┘
```

### Request Flow Diagram

```
                 ┌──────────────┐
                 │   Request    │
                 │  Image URL   │
                 └──────┬───────┘
                        │
                        ▼
            ┌───────────────────────┐
            │  Check Memory Cache   │
            │    (CacheAgent)       │
            └───────┬───────────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
         ▼                     ▼
    ┌────────┐          ┌──────────┐
    │ Found  │          │ Not Found│
    │in Cache│          │          │
    └───┬────┘          └────┬─────┘
        │                    │
        │                    ▼
        │         ┌────────────────────┐
        │         │ Check Disk Storage │
        │         │  (StorageAgent)    │
        │         └─────┬──────────────┘
        │               │
        │     ┌─────────┴─────────┐
        │     │                   │
        │     ▼                   ▼
        │ ┌────────┐       ┌──────────┐
        │ │ Found  │       │ Not Found│
        │ │on Disk │       │          │
        │ └───┬────┘       └────┬─────┘
        │     │                 │
        │     │                 ▼
        │     │      ┌────────────────────┐
        │     │      │ Download from Net  │
        │     │      │  (NetworkAgent)    │
        │     │      └─────┬──────────────┘
        │     │            │
        │     │            ▼
        │     │      ┌──────────────┐
        │     │      │ Retry Logic? │
        │     │      └─────┬────────┘
        │     │            │
        │     └────────────┴────────────┐
        │                               │
        ▼                               ▼
  ┌─────────────┐              ┌──────────────┐
  │ Save to     │              │ Notify       │
  │ Cache+Disk  │──────────────▶  Observers   │
  └─────────────┘              └──────┬───────┘
                                      │
                                      ▼
                               ┌──────────────┐
                               │ Return Image │
                               │  to Client   │
                               └──────────────┘
```

### Configuration System Diagram

```
┌────────────────────────────────────────────────────┐
│      ImageDownloaderConfigProtocol                 │
│  (Main Configuration Interface)                    │
└──────────┬─────────────┬──────────────┬────────────┘
           │             │              │
    ┌──────▼──────┐  ┌───▼───────┐  ┌───▼───────────┐
    │  Network    │  │   Cache   │  │   Storage     │
    │   Config    │  │   Config  │  │    Config     │
    └──────┬──────┘  └───┬───────┘  └───┬───────────┘
           │             │              │
           ▼             ▼              ▼
    ┌───────────────────────────────────────────────┐
    │          Implementations                      │
    │  • DefaultConfig                              │
    │  • FastConfig                                 │
    │  • OfflineFirstConfig                         │
    │  • LowMemoryConfig                            │
    │  • Custom configs via ConfigBuilder           │
    └───────────────────────────────────────────────┘
```

---

## Component Details

### 1. ImageDownloaderManager

**Responsibility:** Central coordinator for all image operations

**Key Features:**
- Request routing and deduplication
- Configuration management (injectable per-request)
- Observer pattern coordination
- Priority queue management
- Cancellation handling

**Interface:**
```swift
class ImageDownloaderManager {
    // Singleton
    static let shared: ImageDownloaderManager

    // Factory for custom configs
    static func instance(for config: ImageDownloaderConfigProtocol?) -> ImageDownloaderManager

    // Async/await API
    func requestImage(at url: URL,
                     priority: ResourcePriority,
                     shouldSaveToStorage: Bool?,
                     progress: ImageProgressBlock?,
                     caller: AnyObject?) async throws -> ImageResult

    // Completion handler API
    func requestImage(at url: URL,
                     priority: ResourcePriority,
                     shouldSaveToStorage: Bool?,
                     progress: ImageProgressBlock?,
                     completion: ImageCompletionBlock?,
                     caller: AnyObject?)

    // Configuration
    func configure(_ configuration: ImageDownloaderConfiguration)

    // Cache management
    func clearCache(for url: URL)
    func clearAllCache()

    // Observers
    func addObserver(_ observer: ImageDownloaderObserver)
    func removeObserver(_ observer: ImageDownloaderObserver)
}
```

### 2. CacheAgent

**Responsibility:** In-memory image caching with two-tier priority system

**Key Features:**
- High-priority cache (persistent until explicit clear)
- Low-priority cache (LRU eviction when full)
- Thread-safe access
- Fast O(1) lookup
- Automatic memory management

**Structure:**
```swift
class CacheAgent {
    private var highPriorityCache: [String: UIImage]
    private var lowPriorityCache: [String: UIImage]
    private let maxHighPrioritySize: Int
    private let maxLowPrioritySize: Int
    private let queue: DispatchQueue

    func save(_ image: UIImage, key: String, priority: ResourcePriority)
    func get(for key: String) -> UIImage?
    func clear(for key: String)
    func clearAll()
}
```

**Cache Eviction Strategy:**
- High priority: Never evicted (until clearCache/clearAllCache)
- Low priority: LRU (Least Recently Used) when full

### 3. NetworkAgent

**Responsibility:** Image downloading with queue management

**Key Features:**
- Concurrent download queue (configurable limit)
- Priority-based scheduling
- Progress tracking
- Retry with exponential backoff
- Request deduplication
- Custom headers/authentication
- Cancellation support

**Structure:**
```swift
class NetworkAgent {
    private var session: URLSession
    private var downloadQueue: OperationQueue
    private var activeDownloads: [URL: URLSessionTask]
    private let maxConcurrentDownloads: Int

    func download(from url: URL,
                 priority: ResourcePriority,
                 progress: ((CGFloat) -> Void)?,
                 completion: @escaping (Data?, Error?) -> Void)

    func cancelDownload(for url: URL)
}
```

**Download Priority:**
1. High priority downloads execute first
2. Low priority downloads queued
3. Queue size limited by `maxConcurrentDownloads`

### 4. StorageAgent

**Responsibility:** Disk persistence with compression

**Key Features:**
- FileManager-based storage
- Configurable compression (JPEG, Adaptive)
- Path providers (Default, Hierarchical)
- Async save/load operations
- Storage size management
- Automatic cleanup

**Structure:**
```swift
class StorageAgent {
    private let fileManager: FileManager
    private let storageDirectory: URL
    private var compressionProvider: ImageCompressionProvider?
    private var pathProvider: StoragePathProvider?

    func save(_ image: UIImage, for url: URL, completion: @escaping (Bool) -> Void)
    func load(for url: URL, completion: @escaping (UIImage?) -> Void)
    func clear(for url: URL)
    func clearAll()
    func storageSize() -> UInt
}
```

**Storage Path:**
```
/Library/Caches/ImageDownloader/
  ├── cdn.example.com/
  │   ├── a1b2c3d4.jpg
  │   └── e5f6g7h8.jpg
  └── images.site.com/
      └── i9j0k1l2.jpg
```

### 5. ResourceModel

**Responsibility:** State management for image resources

**Key Features:**
- Unique identifier (MD5 hash of URL)
- State tracking (downloading, completed, failed)
- Metadata storage
- Last access time (for LRU)
- Reference counting

**Structure:**
```swift
class ResourceModel {
    let identifier: String          // MD5 hash
    let url: URL
    var state: ResourceState
    var image: UIImage?
    var error: Error?
    var lastAccessed: Date
    var priority: ResourcePriority

    // Observers for this resource
    var completionHandlers: [(ImageCompletionBlock)]
    var progressHandlers: [(ImageProgressBlock)]
}

enum ResourceState {
    case idle
    case downloading(progress: CGFloat)
    case completed
    case failed(Error)
    case cancelled
}
```

---

## Data Flow

### 1. Image Request Flow

```
1. Client calls UIImage.load(from:config:)
   └─▶ Creates URLRequest with config

2. Manager.requestImage()
   ├─▶ Check request deduplication
   │   └─▶ If duplicate, join existing request
   │
   ├─▶ Create/get ResourceModel
   │
   └─▶ Check CacheAgent
       ├─▶ If found → Return immediately
       │
       └─▶ Check StorageAgent
           ├─▶ If found → Save to cache → Return
           │
           └─▶ NetworkAgent.download()
               ├─▶ Apply retry policy
               ├─▶ Track progress
               ├─▶ Download data
               └─▶ Decode image
                   ├─▶ Save to cache
                   ├─▶ Save to storage (if enabled)
                   └─▶ Notify observers
```

### 2. Configuration Flow

```
1. Client provides config (or nil for default)
   └─▶ Manager.instance(for: config)

2. Config injection
   ├─▶ NetworkConfig → NetworkAgent
   ├─▶ CacheConfig → CacheAgent
   └─▶ StorageConfig → StorageAgent

3. Request execution with config
   └─▶ Each agent uses injected config
```

### 3. Observer Notification Flow

```
1. Image state changes
   └─▶ ResourceModel updates state

2. Manager detects change
   └─▶ Notifies all registered observers

3. Observers receive callbacks
   ├─▶ imageDownloaderDidStart(url:)
   ├─▶ imageDownloaderDidUpdateProgress(url:progress:)
   └─▶ imageDownloaderDidComplete(url:image:error:)
```

---

## Design Patterns

### 1. Singleton Pattern

**Used in:** ImageDownloaderManager

```swift
class ImageDownloaderManager {
    static let shared = ImageDownloaderManager()
    private init() { }
}
```

**Rationale:** Single source of truth for image operations

### 2. Factory Pattern

**Used in:** Manager instance creation

```swift
static func instance(for config: ImageDownloaderConfigProtocol?) -> ImageDownloaderManager {
    // Create configured instance
}
```

**Rationale:** Flexible instance creation with different configs

### 3. Observer Pattern

**Used in:** Event notifications

```swift
protocol ImageDownloaderObserver: AnyObject {
    func imageDownloaderDidStart(url: URL)
    func imageDownloaderDidComplete(url: URL, image: UIImage?, error: Error?)
    func imageDownloaderDidUpdateProgress(url: URL, progress: CGFloat)
}
```

**Rationale:** Decoupled event notification system

### 4. Strategy Pattern

**Used in:** Compression and path providers

```swift
protocol ImageCompressionProvider {
    func compress(_ image: UIImage) -> Data?
}

class JPEGCompressionProvider: ImageCompressionProvider { }
class AdaptiveCompressionProvider: ImageCompressionProvider { }
```

**Rationale:** Pluggable compression strategies

### 5. Builder Pattern

**Used in:** Configuration building

```swift
ConfigBuilder()
    .maxConcurrentDownloads(8)
    .timeout(30)
    .build()
```

**Rationale:** Fluent, readable configuration creation

### 6. Protocol-Oriented Design

**Used in:** Configuration system

```swift
protocol ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol { get }
    var cacheConfig: CacheConfigProtocol { get }
    var storageConfig: StorageConfigProtocol { get }
}
```

**Rationale:** Testable, mockable, flexible architecture

---

## Threading Model

### Thread Safety

```
┌────────────────────────────────────────────────────┐
│              Main Thread                           │
│  • UIImageView updates                             │
│  • SwiftUI state changes                           │
│  • Client callbacks                                │
└────────────┬───────────────────────────────────────┘
             │
┌────────────▼───────────────────────────────────────┐
│         Manager Queue (Serial)                     │
│  • Request coordination                            │
│  • State management                                │
│  • Observer notifications                          │
└────┬───────────────────────┬───────────────────────┘
     │                       │
┌────▼──────────┐     ┌──────▼─────────────┐
│ Cache Queue   │     │  Network Queue     │
│  (Concurrent) │     │   (Concurrent)     │
│  • Read ops   │     │  • URLSession      │
│  • Write ops  │     │  • Downloads       │
└───────────────┘     └──────┬─────────────┘
                             │
                      ┌──────▼─────────────┐
                      │  Storage Queue     │
                      │   (Background)     │
                      │  • File I/O        │
                      │  • Compression     │
                      └────────────────────┘
```

### Queue Types

1. **Main Queue**
   - UI updates
   - Client callbacks
   - Observer notifications (final delivery)

2. **Manager Queue** (Serial)
   - Request routing
   - State management
   - Coordination

3. **Cache Queue** (Concurrent)
   - Fast read/write operations
   - Barrier flags for writes

4. **Network Queue** (Concurrent)
   - URLSession operations
   - Download management
   - Limited by `maxConcurrentDownloads`

5. **Storage Queue** (Background)
   - File I/O operations
   - Image compression
   - Storage management

### Async/Await Integration

```swift
// Uses Swift structured concurrency
func requestImage(at url: URL) async throws -> ImageResult {
    try await withCheckedThrowingContinuation { continuation in
        requestImage(at: url) { image, error, fromCache, fromStorage in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let image = image {
                continuation.resume(returning: ImageResult(...))
            }
        }
    }
}
```

---

## Memory Management

### Cache Memory Budget

```
High Priority Cache: 50-200 images (configurable)
Low Priority Cache:  100-500 images (configurable)

Estimated Memory:
  - Small images (avatars): ~50KB each
  - Medium images (feed): ~500KB each
  - Large images (photos): ~2MB each

Example:
  FastConfig: 100 high + 200 low = 300 images
  If medium size: 300 × 500KB = 150MB
```

### Memory Warnings

```swift
// Automatic cleanup on memory warnings
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.clearLowPriorityCache()
}
```

### Weak References

```swift
// Callers stored as weak references to prevent retain cycles
private var callerMap: [String: [Weak<AnyObject>]] = [:]

struct Weak<T: AnyObject> {
    weak var value: T?
}
```

---

## Performance Optimizations

### 1. Request Deduplication

Prevents duplicate concurrent requests:

```swift
// Multiple views request same image
imageView1.setImage(with: url)  // Starts download
imageView2.setImage(with: url)  // Joins existing
imageView3.setImage(with: url)  // Joins existing

// Result: ONE network request for all three views
```

**Savings:** 50-90% bandwidth in list/grid views

### 2. Two-Tier Caching

```
High Priority Cache (persistent)
  ↓
Low Priority Cache (LRU)
  ↓
Disk Storage
  ↓
Network
```

**Benefits:**
- Fast access for important images
- Memory-efficient for less important images
- Reduced network usage

### 3. Concurrent Operations

```swift
// Multiple downloads in parallel
maxConcurrentDownloads: 8

// Multiple cache reads in parallel
cacheQueue.async(flags: .barrier) { /* write */ }
cacheQueue.async { /* read */ }
```

**Benefits:**
- Faster overall loading
- Better CPU utilization
- Responsive UI

### 4. Lazy Compression

```swift
// Compress only when saving to disk
storageAgent.save(image) {
    let compressed = compressionProvider.compress(image)
    fileManager.write(compressed)
}
```

**Benefits:**
- Faster cache access (uncompressed)
- Smaller disk usage (compressed)
- Balanced performance/storage

### 5. Progress Tracking

```swift
// Real-time progress updates
downloadTask.observe(\.progress.fractionCompleted) { task, _ in
    progressHandler?(task.progress.fractionCompleted)
}
```

**Benefits:**
- Better UX
- User feedback during downloads
- Cancellation opportunities

---

## Metrics and Monitoring

### Available Metrics

```swift
// Cache statistics
let highCount = manager.cacheSizeHigh()
let lowCount = manager.cacheSizeLow()

// Storage statistics
let storageBytes = manager.storageSizeBytes()

// Active downloads
let activeCount = manager.activeDownloadCount()
```

### Debug Logging

```swift
let config = ConfigBuilder()
    .enableDebugLogging()
    .build()

// Logs:
// [ImageDownloader] Starting download: https://...
// [ImageDownloader] Progress: 50% - https://...
// [ImageDownloader] Completed: https://... (from cache)
```

---

## Best Practices

### 1. Use Appropriate Priority

```swift
// High priority: visible, important
avatarImageView.setImage(with: url, priority: .high)

// Low priority: backgrounds, off-screen
backgroundImageView.setImage(with: url, priority: .low)
```

### 2. Cancel When Appropriate

```swift
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.cancelImageLoading()
}
```

### 3. Match Config to Use Case

```swift
// Fast config for small, frequent images
avatarImageView.setImage(with: url, config: FastConfig.shared)

// Offline-first for large, important images
photoImageView.setImage(with: url, config: OfflineFirstConfig.shared)
```

### 4. Monitor Memory Usage

```swift
// Respond to memory warnings
clearLowPriorityCache()

// Use low memory config when needed
LowMemoryConfig.shared
```

---

## Future Enhancements

See [ROADMAP.md](ROADMAP.md) for planned improvements:

- Actor-based concurrency
- Combine framework integration
- Progressive image loading
- WebP/AVIF format support
- Advanced caching strategies

---

## More Resources

- **[Complete Documentation](../DOCUMENTATION.md)** - Full library documentation
- **[Configuration Guide](CONFIGURATION.md)** - Detailed configuration options
- **[Examples](EXAMPLES.md)** - Real-world usage examples
- **[Migration Guide](MIGRATION_GUIDE.md)** - Upgrading from older versions

---

**Architecture Document Version:** 1.0
**Last Updated:** 2025-01-06