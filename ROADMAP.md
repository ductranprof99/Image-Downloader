# ImageDownloader Library - Roadmap

## Current Architecture Analysis

### Existing Components
```
ImageDownloader/
├── Manager/        - ImageDownloaderManager (Singleton coordinator)
├── CacheAgent/     - In-memory cache (High/Low priority)
├── NetworkAgent/   - Download manager with queue
├── StorageAgent/   - Disk persistence
├── Observer/       - Event notification system
└── Model/          - ResourceModel (state management)
```

---

## Task List for ImageDownloader Improvements

### **Task 1: Protocol-Based Multi-Framework Adapter**
Create protocol layer to support UIKit, SwiftUI, ComponentKit with clean abstractions

**Subtasks:**
- [ ] 1.1 - Design `ImageViewProtocol` for framework-agnostic interface
- [ ] 1.2 - Create UIKit adapter (enhance `AsyncImageView`)
- [ ] 1.3 - Create SwiftUI adapter (`AsyncImage` view)
- [ ] 1.4 - Create ComponentKit adapter (refactor `NetworkImageView`)
- [ ] 1.5 - Create protocol-based loading coordinator
- [ ] 1.6 - Document adapter pattern and usage examples

### **Task 2: Configuration Inheritance System**
Implement configuration system with hierarchical overrides

**Subtasks:**
- [ ] 2.1 - Design `ImageDownloaderConfiguration` protocol
- [ ] 2.2 - Create `BaseConfiguration` (global defaults)
- [ ] 2.3 - Create `RequestConfiguration` (per-request overrides)
- [ ] 2.4 - Implement configuration merging/inheritance logic
- [ ] 2.5 - Add configuration validation
- [ ] 2.6 - Create configuration builder pattern

### **Task 3: Network Layer Improvements**
Enhance networking capabilities with modern features

**Subtasks:**
- [ ] 3.1 - Add retry mechanism with exponential backoff
- [ ] 3.2 - Implement request deduplication
- [ ] 3.3 - Add support for custom headers/authentication
- [ ] 3.4 - Implement bandwidth throttling
- [ ] 3.5 - Add WebP/AVIF format support
- [ ] 3.6 - Implement progressive image loading
- [ ] 3.7 - Add request interceptor pattern
- [ ] 3.8 - Network reachability monitoring

---

## Task 1: Protocol-Based Multi-Framework Adapter

### Design

#### Core Protocol
```swift
protocol ImageViewAdapter {
    // Set the image
    func setImage(_ image: UIImage?)

    // Set placeholder
    func setPlaceholder(_ placeholder: UIImage?)

    // Show loading state
    func showLoading(_ show: Bool)

    // Update progress
    func updateProgress(_ progress: CGFloat)

    // Handle error
    func showError(_ error: Error)

    // Optional: Animation support
    func setImage(_ image: UIImage?, animated: Bool)
}
```

#### Framework Adapters

**1. UIKit Adapter**
```swift
class AsyncImageView: UIImageView, ImageViewAdapter {
    static func create(
        url: URL,
        options: ImageLoadOptions
    ) -> AsyncImageView

    func setImage(_ image: UIImage?, animated: Bool)
    func updateProgress(_ progress: CGFloat)
}
```

**2. SwiftUI Adapter**
```swift
struct AsyncImage: View {
    let url: URL
    let options: ImageLoadOptions

    var body: some View {
        // SwiftUI implementation with @State
    }
}
```

**3. ComponentKit Adapter**
```swift
class NetworkImageView: CKCompositeComponent {
    static func new(
        url: URL,
        options: ImageLoadOptions,
        size: CKComponentSize
    ) -> Self
}
```

---

## Task 2: Configuration Inheritance System

### Design

#### Configuration Hierarchy
```
Global Config (ImageDownloaderManager)
    ↓
Request Config (Per-request)
    ↓
Runtime Override (Dynamic)
```

#### Implementation

```swift
// Base Configuration Protocol
protocol ImageDownloaderConfiguration {
    var cachePriority: ResourcePriority { get set }
    var shouldSaveToStorage: Bool { get set }
    var timeout: TimeInterval { get set }
    var maxRetries: Int { get set }
    var headers: [String: String]? { get set }
    var allowsCellularAccess: Bool { get set }
    var maxImageSize: CGFloat { get set }
}

// Global Configuration (Singleton defaults)
class GlobalConfiguration: ImageDownloaderConfiguration {
    static let shared = GlobalConfiguration()

    var cachePriority: ResourcePriority = .normal
    var shouldSaveToStorage: Bool = false
    var timeout: TimeInterval = 30
    var maxRetries: Int = 3
    var headers: [String: String]? = nil
    var allowsCellularAccess: Bool = true
    var maxImageSize: CGFloat = 1024
}

// Request Configuration (Per-request overrides)
struct RequestConfiguration: ImageDownloaderConfiguration {
    var cachePriority: ResourcePriority
    var shouldSaveToStorage: Bool
    var timeout: TimeInterval
    var maxRetries: Int
    var headers: [String: String]?
    var allowsCellularAccess: Bool
    var maxImageSize: CGFloat

    init(base: ImageDownloaderConfiguration = GlobalConfiguration.shared) {
        self.cachePriority = base.cachePriority
        self.shouldSaveToStorage = base.shouldSaveToStorage
        self.timeout = base.timeout
        self.maxRetries = base.maxRetries
        self.headers = base.headers
        self.allowsCellularAccess = base.allowsCellularAccess
        self.maxImageSize = base.maxImageSize
    }
}

// Configuration Builder
class ConfigurationBuilder {
    private var config: RequestConfiguration

    init() {
        config = RequestConfiguration()
    }

    func withCachePriority(_ priority: ResourcePriority) -> Self {
        config.cachePriority = priority
        return self
    }

    func withStorageEnabled(_ enabled: Bool) -> Self {
        config.shouldSaveToStorage = enabled
        return self
    }

    func withTimeout(_ timeout: TimeInterval) -> Self {
        config.timeout = timeout
        return self
    }

    func withRetries(_ retries: Int) -> Self {
        config.maxRetries = retries
        return self
    }

    func withHeaders(_ headers: [String: String]) -> Self {
        config.headers = headers
        return self
    }

    func build() -> RequestConfiguration {
        return config
    }
}
```

#### Usage Example
```swift
// Global configuration (set once)
GlobalConfiguration.shared.cachePriority = .low
GlobalConfiguration.shared.shouldSaveToStorage = true

// Per-request override
let config = ConfigurationBuilder()
    .withCachePriority(.high)
    .withStorageEnabled(true)
    .withRetries(5)
    .build()

ImageDownloaderManager.shared.requestImage(
    at: url,
    configuration: config,
    completion: { image, error in }
)
```

---

## Task 3: Network Layer Improvements

### 3.1 Retry Mechanism with Exponential Backoff

```swift
class RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let backoffMultiplier: Double

    static let `default` = RetryPolicy(maxRetries: 3, baseDelay: 1.0, backoffMultiplier: 2.0)
    static let aggressive = RetryPolicy(maxRetries: 5, baseDelay: 0.5, backoffMultiplier: 1.5)
    static let conservative = RetryPolicy(maxRetries: 2, baseDelay: 2.0, backoffMultiplier: 3.0)

    func delay(forAttempt attempt: Int) -> TimeInterval {
        return baseDelay * pow(backoffMultiplier, Double(attempt - 1))
    }
}
```

### 3.2 Request Deduplication

```swift
// Prevent multiple simultaneous requests for same URL
class RequestDeduplicator {
    private var pendingRequests: [URL: [(caller: AnyObject, completion: ImageCompletionHandler)]] = [:]

    func shouldExecuteRequest(for url: URL) -> Bool {
        return pendingRequests[url] == nil
    }

    func addPendingRequest(
        for url: URL,
        caller: AnyObject,
        completion: @escaping ImageCompletionHandler
    ) {
        if pendingRequests[url] == nil {
            pendingRequests[url] = []
        }
        pendingRequests[url]?.append((caller, completion))
    }

    func notifyCompletion(
        for url: URL,
        image: UIImage?,
        error: Error?
    ) {
        guard let requests = pendingRequests[url] else { return }

        for request in requests {
            request.completion(image, error, false, false)
        }

        pendingRequests[url] = nil
    }
}
```

### 3.3 Custom Headers & Authentication

```swift
extension NetworkAgent {
    var defaultHeaders: [String: String] = [:]
    var authenticationHandler: ((inout URLRequest) -> Void)?

    func setDefaultHeaders(_ headers: [String: String]) {
        self.defaultHeaders = headers
    }

    func setAuthenticationHandler(_ handler: @escaping (inout URLRequest) -> Void) {
        self.authenticationHandler = handler
    }
}

// Usage
ImageDownloaderManager.shared.setDefaultHeaders([
    "User-Agent": "MyApp/1.0",
    "Accept": "image/*"
])

ImageDownloaderManager.shared.setAuthenticationHandler { request in
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

### 3.4 Bandwidth Throttling

```swift
class BandwidthThrottler {
    var maxBytesPerSecond: Int = 0 // 0 = unlimited

    private var currentBytesThisSecond: Int = 0
    private var lastResetTime: Date = Date()

    func shouldThrottle(bytesToDownload: Int) -> Bool {
        guard maxBytesPerSecond > 0 else { return false }

        let now = Date()
        if now.timeIntervalSince(lastResetTime) >= 1.0 {
            currentBytesThisSecond = 0
            lastResetTime = now
        }

        if currentBytesThisSecond + bytesToDownload > maxBytesPerSecond {
            return true
        }

        currentBytesThisSecond += bytesToDownload
        return false
    }
}
```

### 3.5 Progressive Image Loading

```swift
// Load low-quality first, then high-quality
func requestProgressiveImage(
    at url: URL,
    thumbnailCallback: @escaping (UIImage) -> Void,
    fullImageCallback: @escaping (UIImage) -> Void
) {
    // Load thumbnail first
    let thumbnailURL = generateThumbnailURL(from: url)
    requestImage(at: thumbnailURL) { image, error in
        if let image = image {
            thumbnailCallback(image)
        }
    }

    // Then load full image
    requestImage(at: url) { image, error in
        if let image = image {
            fullImageCallback(image)
        }
    }
}
```

### 3.6 Format Support (WebP, AVIF)

```swift
class ImageDecoder {
    static func decode(_ data: Data, format: ImageFormat) -> UIImage? {
        switch format {
        case .jpeg, .png:
            return UIImage(data: data)
        case .webp:
            return decodeWebP(data)
        case .avif:
            return decodeAVIF(data)
        }
    }

    static func supports(_ format: ImageFormat) -> Bool {
        switch format {
        case .jpeg, .png: return true
        case .webp: return true // Requires WebP decoder
        case .avif: return false // Future support
        }
    }

    private static func decodeWebP(_ data: Data) -> UIImage? {
        // WebP decoding implementation
        return nil
    }

    private static func decodeAVIF(_ data: Data) -> UIImage? {
        // AVIF decoding implementation
        return nil
    }
}

enum ImageFormat {
    case jpeg
    case png
    case webp
    case avif
}
```

### 3.7 Request Interceptor Pattern

```swift
protocol RequestInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest
    func didComplete(
        _ request: URLRequest,
        response: URLResponse?,
        error: Error?
    )
}

class LoggingInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) -> URLRequest {
        print("📤 Request: \(request.url?.absoluteString ?? "")")
        return request
    }

    func didComplete(
        _ request: URLRequest,
        response: URLResponse?,
        error: Error?
    ) {
        if let error = error {
            print("❌ Error: \(error.localizedDescription)")
        } else {
            print("✅ Success: \(request.url?.absoluteString ?? "")")
        }
    }
}

// Usage
ImageDownloaderManager.shared.addInterceptor(LoggingInterceptor())
```

### 3.8 Network Reachability

```swift
import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isReachable: Bool = true
    var isWiFi: Bool = false
    var onReachabilityChange: ((Bool) -> Void)?

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachable = path.status == .satisfied
            self?.isWiFi = path.usesInterfaceType(.wifi)
            self?.onReachabilityChange?(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}

// Usage
NetworkMonitor.shared.onReachabilityChange = { reachable in
    if reachable {
        print("Network is reachable")
        ImageDownloaderManager.shared.resumeDownloads()
    } else {
        print("Network is unreachable")
        ImageDownloaderManager.shared.pauseDownloads()
    }
}
NetworkMonitor.shared.startMonitoring()
```

---

## Current Strengths

### Good Sides of ImageDownloader Library

1. **✅ Layered Architecture**
   - Clear separation: Manager → Cache → Network → Storage
   - Each layer has single responsibility
   - Easy to test and maintain

2. **✅ Two-Tier Caching**
   - High priority cache (persistent)
   - Low priority cache (evictable)
   - Smart memory management

3. **✅ Observer Pattern**
   - Decoupled event notification
   - Multiple observers supported
   - Clean separation of concerns

4. **✅ Priority-Based Downloads**
   - High priority images load first
   - Queue management
   - Prevents UI blocking

5. **✅ Disk Persistence**
   - Storage agent for offline support
   - Configurable per-request
   - Reduces network usage

6. **✅ Progress Tracking**
   - Real-time download progress
   - UI feedback support
   - Better UX

7. **✅ Caller-Based Cancellation**
   - Cancel specific requests
   - Prevents memory leaks
   - Good for scrolling views

8. **✅ Resource Model**
   - Centralized state management
   - MD5 identifier for dedup
   - Last access tracking for LRU

9. **✅ Statistics API**
   - Cache size monitoring
   - Active downloads count
   - Storage size tracking

10. **✅ Swift-First Design**
    - Modern Swift API
    - Type-safe closures
    - Protocol-oriented architecture

---

## Current Limitations

### Areas for Improvement

1. **Framework Coupling**
   - **Issue**: Some framework-specific code in core
   - **Impact**: Harder to add new framework support
   - **Fix**: Protocol-based adapter (Task 1)

2. **No Retry Mechanism**
   - **Issue**: Failed downloads don't retry
   - **Impact**: Poor UX on flaky networks
   - **Fix**: Exponential backoff retry (Task 3.1)

3. **Request Duplication**
   - **Issue**: Multiple requests for same URL
   - **Impact**: Wasted bandwidth and memory
   - **Fix**: Request deduplication (Task 3.2)

4. **Limited Format Support**
   - **Issue**: Only supports formats UIImage can decode
   - **Impact**: No WebP, AVIF, or modern formats
   - **Fix**: Custom decoder (Task 3.6)

5. **No Configuration Inheritance**
   - **Issue**: Can't override global settings per-request easily
   - **Impact**: Inflexible API, code duplication
   - **Fix**: Configuration system (Task 2)

6. **No Authentication Support**
   - **Issue**: Can't add custom headers or auth tokens
   - **Impact**: Can't use with private CDNs/APIs
   - **Fix**: Header/auth support (Task 3.3)

7. **No Network Monitoring**
   - **Issue**: Doesn't detect network changes
   - **Impact**: Unnecessary failures, poor offline UX
   - **Fix**: Reachability monitor (Task 3.8)

8. **No Bandwidth Control**
   - **Issue**: Can't throttle downloads
   - **Impact**: Cellular data usage concerns
   - **Fix**: Bandwidth throttler (Task 3.4)

9. **No Progressive Loading**
   - **Issue**: Wait for full image before displaying
   - **Impact**: Slow perceived performance
   - **Fix**: Progressive loading (Task 3.5)

10. **No Request Interceptors**
    - **Issue**: Can't modify requests before sending
    - **Impact**: Hard to add logging, analytics, etc.
    - **Fix**: Interceptor pattern (Task 3.7)

---

## Priority Ranking

### High Priority (Must Have for v2.1)
1. **Protocol-based adapters** (Task 1) - Better framework support
2. **Configuration inheritance** (Task 2) - More flexible API
3. **Retry mechanism** (Task 3.1) - Better reliability

### Medium Priority (Nice to Have for v2.2)
4. Request deduplication (Task 3.2)
5. Custom headers/auth (Task 3.3)
6. Network monitoring (Task 3.8)

### Low Priority (Future Enhancements for v2.3+)
7. Progressive loading (Task 3.5)
8. Format support (Task 3.6)
9. Bandwidth throttling (Task 3.4)
10. Request interceptors (Task 3.7)

---

## Demo App Structure

### Recommended Screens

1. **Framework Comparison Screen**
   - Split view showing same image in all frameworks
   - Performance metrics side-by-side
   - SwiftUI vs UIKit vs ComponentKit

2. **Feature Showcase Screen**
   - Priority-based loading demo
   - Progress tracking demo
   - Cache hit/miss visualization
   - Storage persistence demo

3. **Configuration Demo Screen**
   - Global vs per-request config
   - Override examples
   - Builder pattern usage

4. **Network Scenarios Screen**
   - Retry on failure
   - Offline mode
   - Slow network simulation
   - Cellular vs WiFi

5. **Performance Metrics Screen**
   - Cache statistics
   - Network usage
   - Memory usage
   - Storage size

---

## Release Roadmap

### Version 2.1.0 (Q1 2026)
- [ ] Protocol-based multi-framework adapter system
- [ ] Configuration inheritance (global → request → runtime)
- [ ] Request deduplication
- [ ] Retry mechanism with exponential backoff

### Version 2.2.0 (Q2 2026)
- [ ] Custom headers/authentication support
- [ ] Network reachability monitoring
- [ ] Bandwidth throttling
- [ ] Enhanced statistics and analytics

### Version 2.3.0 (Q3 2026)
- [ ] Progressive image loading
- [ ] WebP/AVIF format support
- [ ] Request interceptor pattern
- [ ] Advanced caching strategies

### Version 3.0.0 (Q4 2026)
- [ ] Complete SwiftUI support with native views
- [ ] Combine framework integration
- [ ] Async/await API
- [ ] Actor-based concurrency

---

## Next Steps

1. **Review this roadmap** - Confirm priorities and approach
2. **Start with Task 1** - Protocol-based adapters (required for better architecture)
3. **Implement Task 2** - Configuration system (flexible API)
4. **Add Task 3.1** - Retry mechanism (better reliability)
5. **Build demo app** - Showcase all features
6. **Create documentation** - Comprehensive guides

Ready to start implementation!

---

**Document Version:** 2.0
**Created:** 2025-10-05
**Last Updated:** 2025-10-06
**Status:** Ready for v2.1.0 Development
