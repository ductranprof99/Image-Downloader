# ImageDownloader - Configuration Guide

Complete guide to configuring ImageDownloader for your specific needs.

---

## Table of Contents

1. [Overview](#overview)
2. [Configuration Architecture](#configuration-architecture)
3. [Preset Configurations](#preset-configurations)
4. [ConfigBuilder API](#configbuilder-api)
5. [Custom Configurations](#custom-configurations)
6. [Configuration Patterns](#configuration-patterns)
7. [Network Configuration](#network-configuration)
8. [Cache Configuration](#cache-configuration)
9. [Storage Configuration](#storage-configuration)
10. [Best Practices](#best-practices)

---

## Overview

ImageDownloader uses a **protocol-based injectable configuration system** that allows you to:

- Use different configs for different requests
- Create preset configs for common scenarios
- Build custom configs with fluent API
- Override global settings per-request
- Test and mock configurations easily

### Philosophy

Instead of one global configuration, **inject config per request**:

```swift
// ✅ Modern approach: Different configs for different needs
let avatar = try await UIImage.load(from: avatarURL, config: FastConfig.shared)
let photo = try await UIImage.load(from: photoURL, config: OfflineFirstConfig.shared)

// ⚠️ Old approach: One global config for everything
ImageDownloaderManager.shared.configure(globalConfig)
```

---

## Configuration Architecture

### Protocol Hierarchy

```
ImageDownloaderConfigProtocol (main protocol)
├── NetworkConfigProtocol (downloads, retry, auth)
├── CacheConfigProtocol (memory cache settings)
└── StorageConfigProtocol (disk storage, compression)
```

### Main Protocol

```swift
protocol ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol { get }
    var cacheConfig: CacheConfigProtocol { get }
    var storageConfig: StorageConfigProtocol { get }
    var enableDebugLogging: Bool { get }
}
```

### Network Configuration

```swift
protocol NetworkConfigProtocol {
    var maxConcurrentDownloads: Int { get }
    var timeout: TimeInterval { get }
    var retryPolicy: RetryPolicy { get }
    var customHeaders: [String: String]? { get }
    var authenticationHandler: ((inout URLRequest) -> Void)? { get }
    var allowsCellularAccess: Bool { get }
}
```

### Cache Configuration

```swift
protocol CacheConfigProtocol {
    var highPriorityCacheSize: Int { get }
    var lowPriorityCacheSize: Int { get }
}
```

### Storage Configuration

```swift
protocol StorageConfigProtocol {
    var enableStorage: Bool { get }
    var compressionProvider: (any ImageCompressionProvider)? { get }
    var pathProvider: (any StoragePathProvider)? { get }
}
```

---

## Preset Configurations

### 1. DefaultConfig - Balanced Settings

**Best for:** General-purpose usage

```swift
let config = DefaultConfig.shared

// Settings:
// - 4 concurrent downloads
// - 30s timeout
// - 50/100 cache limits (high/low)
// - Default retry policy
// - Storage enabled
```

**Use cases:**
- Standard app images
- General content loading
- Balanced performance and memory

**Example:**
```swift
let image = try await UIImage.load(from: url, config: DefaultConfig.shared)
```

### 2. FastConfig - High Performance

**Best for:** High-traffic apps, fast networks

```swift
let config = FastConfig.shared

// Settings:
// - 8 concurrent downloads
// - 20s timeout
// - 100/200 cache limits
// - Aggressive retry (5 retries, 0.5s base)
// - JPEG compression (faster I/O)
```

**Use cases:**
- Social media feeds
- High-volume image loading
- Fast user interactions
- Performance-critical scenarios

**Example:**
```swift
imageView.setImage(with: url, config: FastConfig.shared)
```

### 3. OfflineFirstConfig - Poor Connectivity

**Best for:** Offline apps, slow networks, expensive data

```swift
let config = OfflineFirstConfig.shared

// Settings:
// - WiFi only (no cellular)
// - 2 concurrent downloads
// - 200/500 cache limits (huge!)
// - Conservative retry (2 retries, 2s base)
// - Adaptive compression
```

**Use cases:**
- Travel/offline apps
- Data-conscious users
- Poor network conditions
- Large image galleries

**Example:**
```swift
imageView.setImage(with: url, config: OfflineFirstConfig.shared)
```

### 4. LowMemoryConfig - Memory Constrained

**Best for:** Memory-limited scenarios, background apps

```swift
let config = LowMemoryConfig.shared

// Settings:
// - 2 concurrent downloads
// - 20/50 cache limits (minimal)
// - Aggressive memory cleanup
// - High JPEG compression (0.7 quality)
```

**Use cases:**
- Widgets
- App extensions
- Background processing
- Low-end devices

**Example:**
```swift
imageView.setImage(with: url, config: LowMemoryConfig.shared)
```

---

## ConfigBuilder API

### Overview

`ConfigBuilder` provides a fluent API for creating custom configurations.

### Basic Usage

```swift
let config = ConfigBuilder()
    .maxConcurrentDownloads(6)
    .timeout(30)
    .cacheSize(high: 100, low: 200)
    .build()

let image = try await UIImage.load(from: url, config: config)
```

### Starting from Preset

```swift
// Start from preset and override specific settings
let config = ConfigBuilder.fast()
    .timeout(60)
    .customHeaders(["X-App": "MyApp"])
    .build()
```

### Available Builders

```swift
ConfigBuilder.default()     // Start from DefaultConfig
ConfigBuilder.fast()        // Start from FastConfig
ConfigBuilder.offlineFirst() // Start from OfflineFirstConfig
ConfigBuilder.lowMemory()   // Start from LowMemoryConfig
```

### All Configuration Methods

#### Network Configuration

```swift
.maxConcurrentDownloads(_ count: Int)
.timeout(_ seconds: TimeInterval)
.retryPolicy(_ policy: RetryPolicy)
.customHeaders(_ headers: [String: String])
.authenticationHandler(_ handler: @escaping (inout URLRequest) -> Void)
.allowsCellularAccess(_ allowed: Bool)
```

#### Cache Configuration

```swift
.cacheSize(high: Int, low: Int)
```

#### Storage Configuration

```swift
.enableStorage(_ enabled: Bool)
.compressionProvider(_ provider: any ImageCompressionProvider)
.pathProvider(_ provider: any StoragePathProvider)
```

#### Debug Configuration

```swift
.enableDebugLogging(_ enabled: Bool = true)
```

### Complete Example

```swift
let config = ConfigBuilder()
    // Network
    .maxConcurrentDownloads(8)
    .timeout(30)
    .retryPolicy(.aggressive)
    .customHeaders([
        "User-Agent": "MyApp/1.0",
        "Accept": "image/webp,image/*"
    ])
    .authenticationHandler { request in
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .allowsCellularAccess(true)

    // Cache
    .cacheSize(high: 150, low: 300)

    // Storage
    .enableStorage(true)
    .compressionProvider(JPEGCompressionProvider(quality: 0.8))
    .pathProvider(DomainHierarchicalPathProvider())

    // Debug
    .enableDebugLogging(true)

    .build()
```

---

## Custom Configurations

### Creating Custom Config Types

```swift
struct MyAppConfig: ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol = MyNetworkConfig()
    var cacheConfig: CacheConfigProtocol = MyCacheConfig()
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

struct MyCacheConfig: CacheConfigProtocol {
    var highPriorityCacheSize = 200
    var lowPriorityCacheSize = 500
}

struct MyStorageConfig: StorageConfigProtocol {
    var enableStorage = true
    var compressionProvider: (any ImageCompressionProvider)? = JPEGCompressionProvider(quality: 0.85)
    var pathProvider: (any StoragePathProvider)? = DomainHierarchicalPathProvider()
}
```

### Usage

```swift
let image = try await UIImage.load(from: url, config: MyAppConfig())
```

---

## Configuration Patterns

### Pattern 1: App-Wide Configs

Define configs once, use everywhere:

```swift
extension ImageDownloaderConfigProtocol {
    static let avatar = FastConfig.shared
    static let photo = OfflineFirstConfig.shared
    static let thumbnail = LowMemoryConfig.shared
}

// Usage throughout app
avatarImageView.setImage(with: avatarURL, config: .avatar)
photoImageView.setImage(with: photoURL, config: .photo)
thumbImageView.setImage(with: thumbURL, config: .thumbnail)
```

### Pattern 2: Per-Feature Configs

```swift
struct SocialMediaConfig {
    // Small, fast avatars
    static let avatar = ConfigBuilder()
        .maxConcurrentDownloads(8)
        .cacheSize(high: 150, low: 300)
        .compressionProvider(JPEGCompressionProvider(quality: 0.7))
        .build()

    // Balanced feed photos
    static let feed = ConfigBuilder()
        .maxConcurrentDownloads(6)
        .cacheSize(high: 100, low: 200)
        .compressionProvider(JPEGCompressionProvider(quality: 0.8))
        .build()

    // Offline-first full photos
    static let fullPhoto = OfflineFirstConfig.shared

    // Fast, low-quality stories (don't save)
    static let story = ConfigBuilder()
        .maxConcurrentDownloads(10)
        .enableStorage(false)
        .compressionProvider(JPEGCompressionProvider(quality: 0.6))
        .build()
}
```

### Pattern 3: Per-Environment Configs

```swift
enum Environment {
    case development, staging, production

    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

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
let image = try await UIImage.load(from: url, config: config)
```

### Pattern 4: Dynamic Config Selection

```swift
class ImageConfigProvider {
    static func config(for imageType: ImageType) -> ImageDownloaderConfigProtocol {
        switch imageType {
        case .avatar:
            return FastConfig.shared
        case .photo:
            return OfflineFirstConfig.shared
        case .thumbnail:
            return LowMemoryConfig.shared
        case .background:
            return ConfigBuilder()
                .maxConcurrentDownloads(2)
                .build()
        }
    }
}

enum ImageType {
    case avatar, photo, thumbnail, background
}

// Usage
let config = ImageConfigProvider.config(for: .avatar)
let image = try await UIImage.load(from: url, config: config)
```

---

## Network Configuration

### Concurrent Downloads

```swift
// Low (saves memory, slower)
.maxConcurrentDownloads(2)

// Default (balanced)
.maxConcurrentDownloads(4)

// High (faster, more memory)
.maxConcurrentDownloads(8)
```

### Timeout

```swift
// Short (fail fast)
.timeout(10)

// Default
.timeout(30)

// Long (slow networks)
.timeout(60)
```

### Retry Policy

```swift
// No retries
.retryPolicy(.none)

// Default: 3 retries, 1s base, 2x multiplier
.retryPolicy(.default)

// Aggressive: 5 retries, 0.5s base, 1.5x multiplier
.retryPolicy(.aggressive)

// Conservative: 2 retries, 2s base, 3x multiplier
.retryPolicy(.conservative)

// Custom
.retryPolicy(RetryPolicy(
    maxRetries: 4,
    baseDelay: 1.0,
    backoffMultiplier: 2.0,
    maxDelay: 30.0
))
```

### Custom Headers

```swift
.customHeaders([
    "User-Agent": "MyApp/1.0",
    "Accept": "image/webp,image/*",
    "X-API-Key": "secret_key"
])
```

### Authentication

```swift
.authenticationHandler { request in
    // Bearer token
    if let token = AuthManager.shared.accessToken {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    // Basic auth
    let credentials = "\(username):\(password)"
    if let base64 = credentials.data(using: .utf8)?.base64EncodedString() {
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
    }
}
```

### Cellular Access

```swift
// Allow cellular
.allowsCellularAccess(true)

// WiFi only
.allowsCellularAccess(false)
```

---

## Cache Configuration

### Cache Size Limits

```swift
// Small cache (memory constrained)
.cacheSize(high: 20, low: 50)

// Default cache
.cacheSize(high: 50, low: 100)

// Large cache (performance)
.cacheSize(high: 100, low: 200)

// Huge cache (offline-first)
.cacheSize(high: 200, low: 500)
```

### Cache Priority Strategy

```swift
// High priority images stay in cache longer
imageView.setImage(with: avatarURL, priority: .high)  // Stays in cache

// Low priority images evicted first
imageView.setImage(with: backgroundURL, priority: .low)  // Evicted when full
```

---

## Storage Configuration

### Enable/Disable Storage

```swift
// Enable disk storage
.enableStorage(true)

// Disable storage (stories, temporary images)
.enableStorage(false)
```

### Compression Providers

#### JPEG Compression

```swift
// High quality (larger files)
.compressionProvider(JPEGCompressionProvider(quality: 0.9))

// Balanced
.compressionProvider(JPEGCompressionProvider(quality: 0.8))

// Low quality (smaller files)
.compressionProvider(JPEGCompressionProvider(quality: 0.6))
```

#### Adaptive Compression

Automatically chooses best compression based on image type:

```swift
.compressionProvider(AdaptiveCompressionProvider())

// PNG → PNG (lossless)
// JPEG → JPEG (0.8 quality)
// Other → JPEG (0.8 quality)
```

### Path Providers

#### Default Path Provider

```swift
// Flat structure: /storage/md5hash.jpg
.pathProvider(DefaultPathProvider())
```

#### Hierarchical Path Provider

```swift
// Domain-based: /storage/cdn.example.com/md5hash.jpg
.pathProvider(DomainHierarchicalPathProvider())
```

---

## Best Practices

### 1. Use Preset Configs When Possible

```swift
// ✅ Good - Use presets
imageView.setImage(with: url, config: FastConfig.shared)

// ❌ Avoid - Recreating similar configs
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .cacheSize(high: 100, low: 200)
    .build()
```

### 2. Define App-Wide Configs

```swift
// ✅ Good - Define once
extension ImageDownloaderConfigProtocol {
    static let avatar = FastConfig.shared
    static let photo = OfflineFirstConfig.shared
}

// ❌ Avoid - Inline configs everywhere
imageView.setImage(with: url, config: FastConfig.shared)
imageView.setImage(with: url, config: FastConfig.shared)
```

### 3. Match Config to Use Case

```swift
// ✅ Good - Right config for use case
avatarImageView.setImage(with: url, config: FastConfig.shared)  // Small, fast
photoImageView.setImage(with: url, config: OfflineFirstConfig.shared)  // Large, keep

// ❌ Avoid - Same config for everything
avatarImageView.setImage(with: url, config: DefaultConfig.shared)
photoImageView.setImage(with: url, config: DefaultConfig.shared)
```

### 4. Use ConfigBuilder for Custom Needs

```swift
// ✅ Good - Custom config when needed
let config = ConfigBuilder.fast()
    .authenticationHandler { request in
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .build()

// ❌ Avoid - Implementing full protocol for small change
struct MyConfig: ImageDownloaderConfigProtocol {
    // 50 lines of code for one small change
}
```

### 5. Environment-Specific Configs

```swift
// ✅ Good - Different configs per environment
#if DEBUG
let config = ConfigBuilder()
    .enableDebugLogging()
    .timeout(60)
    .build()
#else
let config = FastConfig.shared
#endif
```

### 6. Test Your Configs

```swift
class ConfigTests: XCTestCase {
    func testFastConfigLoading() async throws {
        let url = URL(string: "https://example.com/image.jpg")!
        let image = try await UIImage.load(from: url, config: FastConfig.shared)
        XCTAssertNotNil(image)
    }

    func testCustomAuthConfig() async throws {
        let config = ConfigBuilder()
            .authenticationHandler { request in
                request.setValue("Bearer test", forHTTPHeaderField: "Authorization")
            }
            .build()

        let url = URL(string: "https://api.example.com/image.jpg")!
        let image = try await UIImage.load(from: url, config: config)
        XCTAssertNotNil(image)
    }
}
```

---

## Quick Reference

### Preset Configs

| Config | Concurrent | Timeout | Cache (H/L) | Best For |
|--------|-----------|---------|-------------|----------|
| DefaultConfig | 4 | 30s | 50/100 | General use |
| FastConfig | 8 | 20s | 100/200 | Performance |
| OfflineFirstConfig | 2 | 30s | 200/500 | Offline apps |
| LowMemoryConfig | 2 | 30s | 20/50 | Low memory |

### Common Patterns

```swift
// Fast loading
FastConfig.shared

// Authenticated
ConfigBuilder()
    .authenticationHandler { ... }
    .build()

// WiFi only
ConfigBuilder()
    .allowsCellularAccess(false)
    .build()

// No storage
ConfigBuilder()
    .enableStorage(false)
    .build()

// Debug mode
ConfigBuilder()
    .enableDebugLogging()
    .build()
```

---

## More Resources

- **[Complete Documentation](../DOCUMENTATION.md)** - Full library documentation
- **[Examples](EXAMPLES.md)** - Real-world usage examples
- **[Architecture](ARCHITECTURE.md)** - System architecture details
- **[Migration Guide](MIGRATION_GUIDE.md)** - Upgrading from older versions

---

**Configuration Guide Version:** 1.0
**Last Updated:** 2025-01-06
