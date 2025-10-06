# ImageDownloader - Migration Guide

Complete guide for migrating between versions of ImageDownloader.

---

## Table of Contents

1. [From v1.x (Objective-C) to v2.0+](#from-v1x-objective-c-to-v20)
2. [From v2.0 to v2.1](#from-v20-to-v21)
3. [Breaking Changes](#breaking-changes)
4. [Common Migration Patterns](#common-migration-patterns)

---

## From v1.x (Objective-C) to v2.0+

### Overview

Version 2.0 is a complete Swift rewrite with modern async/await support, while maintaining Objective-C compatibility for legacy code.

### Package Name Changes

```swift
// Before (v1.x)
import CNI
import CNIUIKit

// After (v2.0+)
import ImageDownloader
import ImageDownloaderUI
```

### Class Name Changes

| v1.x | v2.0+ | Description |
|------|-------|-------------|
| `CNIManager` | `ImageDownloaderManager` | Main manager singleton |
| `CNIImageView` | `AsyncImageView` | UIKit async image view |
| `CustomNetworkImageView` | `NetworkImageView` | ComponentKit component |

### API Changes

#### Manager API

```swift
// Before (v1.x)
CNIManager.sharedManager().requestImage(
    at: url,
    completion: { image, error, fromCache, fromStorage in
        imageView.image = image
    }
)

// After (v2.0+) - Completion handler
ImageDownloaderManager.shared.requestImage(at: url) { image, error, fromCache, fromStorage in
    imageView.image = image
}

// After (v2.0+) - Async/await (recommended)
Task {
    let result = try await ImageDownloaderManager.shared.requestImage(at: url)
    imageView.image = result.image
}
```

#### UIImageView Extension

```swift
// Before (v1.x)
imageView.cni_setImage(with: url, placeholder: placeholder)

// After (v2.0+)
imageView.setImage(with: url, placeholder: placeholder)
```

#### Progress Tracking

```swift
// Before (v1.x)
CNIManager.sharedManager().requestImage(
    at: url,
    progress: { progress in
        progressView.progress = Float(progress)
    },
    completion: { image, error, fromCache, fromStorage in
        imageView.image = image
    }
)

// After (v2.0+)
imageView.setImage(
    with: url,
    onProgress: { progress in
        progressView.progress = Float(progress)
    },
    onCompletion: { image, error, fromCache, fromStorage in
        // Handle completion
    }
)
```

#### Cache Management

```swift
// Before (v1.x)
CNIManager.sharedManager().clearCache(for: url)
CNIManager.sharedManager().clearAllCache()

// After (v2.0+)
ImageDownloaderManager.shared.clearCache(for: url)
ImageDownloaderManager.shared.clearAllCache()
```

### Configuration Changes

```swift
// Before (v1.x)
let config = CNIConfiguration()
config.maxConcurrentDownloads = 8
config.timeout = 30
CNIManager.sharedManager().configure(with: config)

// After (v2.0+)
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .timeout(30)
    .build()

ImageDownloaderManager.shared.configure(config)
```

### Objective-C Compatibility

If you need to keep Objective-C code working:

```objc
// Objective-C (still works in v2.0+)
@import ImageDownloader;

[[ImageDownloaderManager shared] requestImageAt:url
    priority:ResourcePriorityNormal
    shouldSaveToStorage:YES
    progress:^(CGFloat progress) {
        // Update progress
    }
    completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
        imageView.image = image;
    }
    caller:self];
```

---

## From v2.0 to v2.1

### Overview

Version 2.1 is **100% backward compatible** with v2.0. All existing code continues to work without changes.

### What's New in v2.1

1. **Injectable Configuration** - Pass config per request
2. **UIImage.load()** - Direct image loading extension
3. **Preset Configurations** - FastConfig, OfflineFirstConfig, LowMemoryConfig
4. **ConfigBuilder** - Fluent API for building configs
5. **Retry with Exponential Backoff** - Automatic retry on failures
6. **Request Deduplication** - Prevent duplicate requests
7. **Network Reachability** - Monitor network status

### Backward Compatibility

```swift
// v2.0 code still works in v2.1
ImageDownloaderManager.shared.configure(config)
ImageDownloaderManager.shared.requestImage(at: url) { image, error, _, _ in
    imageView.image = image
}
```

### New Features (Optional Adoption)

#### 1. Injectable Configuration

```swift
// Old way (v2.0) - Global configuration
ImageDownloaderManager.shared.configure(globalConfig)
ImageDownloaderManager.shared.requestImage(at: url) { ... }

// New way (v2.1) - Injectable configuration
let image = try await UIImage.load(from: url, config: FastConfig.shared)

// Or with UIImageView
imageView.setImage(with: url, config: FastConfig.shared)
```

#### 2. UIImage Extension

```swift
// v2.1 only - Direct UIImage loading
let image = try await UIImage.load(from: url)

// With config
let image = try await UIImage.load(from: url, config: FastConfig.shared)

// With progress
UIImage.load(
    from: url,
    progress: { progress in
        print("Loading: \(Int(progress * 100))%")
    },
    completion: { result in
        switch result {
        case .success(let image):
            imageView.image = image
        case .failure(let error):
            print("Error: \(error)")
        }
    }
)
```

#### 3. Preset Configurations

```swift
// v2.1 only - Use preset configs
let avatar = try await UIImage.load(from: avatarURL, config: FastConfig.shared)
let photo = try await UIImage.load(from: photoURL, config: OfflineFirstConfig.shared)
let thumb = try await UIImage.load(from: thumbURL, config: LowMemoryConfig.shared)
```

#### 4. ConfigBuilder Fluent API

```swift
// v2.1 only - Build custom config with fluent API
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .retryPolicy(.aggressive)
    .customHeaders(["User-Agent": "MyApp/1.0"])
    .authenticationHandler { request in
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .build()

let image = try await UIImage.load(from: url, config: config)
```

#### 5. Network Reachability

```swift
// v2.1 only - Monitor network status
NetworkMonitor.shared.startMonitoring()

NetworkMonitor.shared.onReachabilityChange = { isReachable in
    if isReachable {
        print("Network is back!")
    } else {
        print("Network lost!")
    }
}

NetworkMonitor.shared.onConnectionTypeChange = { isWiFi, isCellular in
    if isCellular {
        print("Switched to cellular")
    }
}
```

### Migration Strategy

**Option 1: Keep v2.0 Code (No Changes Needed)**
```swift
// Your existing v2.0 code continues to work
ImageDownloaderManager.shared.requestImage(at: url) { image, error, _, _ in
    imageView.image = image
}
```

**Option 2: Adopt v2.1 Features Gradually**
```swift
// Start using new features where beneficial
// 1. Use preset configs for common cases
imageView.setImage(with: url, config: FastConfig.shared)

// 2. Use UIImage.load() for direct loading
let image = try await UIImage.load(from: url)

// 3. Build custom configs when needed
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .retryPolicy(.aggressive)
    .build()
```

**Option 3: Full Migration to v2.1 Style**
```swift
// Migrate all code to injectable configs
extension ImageDownloaderConfigProtocol {
    static let avatar = FastConfig.shared
    static let photo = OfflineFirstConfig.shared
    static let thumbnail = LowMemoryConfig.shared
}

// Use throughout app
avatarImageView.setImage(with: avatarURL, config: .avatar)
photoImageView.setImage(with: photoURL, config: .photo)
```

---

## Breaking Changes

### v2.0 Breaking Changes (from v1.x)

1. **Package name changed** from `CNI` to `ImageDownloader`
2. **Class names changed** (see table above)
3. **Swift-first API** - Objective-C bridging available but secondary
4. **Minimum iOS version** - iOS 13+ (was iOS 10+)

### v2.1 Breaking Changes

**None!** Version 2.1 is 100% backward compatible with v2.0.

---

## Common Migration Patterns

### Pattern 1: Simple Image Loading

```swift
// v1.x
CNIManager.sharedManager().requestImage(at: url) { image, error, _, _ in
    imageView.image = image
}

// v2.0
ImageDownloaderManager.shared.requestImage(at: url) { image, error, _, _ in
    imageView.image = image
}

// v2.1 (recommended)
imageView.setImage(with: url, config: FastConfig.shared)
```

### Pattern 2: With Placeholder

```swift
// v1.x
imageView.cni_setImage(with: url, placeholder: placeholder)

// v2.0+
imageView.setImage(with: url, placeholder: placeholder)

// v2.1 (with config)
imageView.setImage(with: url, config: FastConfig.shared, placeholder: placeholder)
```

### Pattern 3: Progress Tracking

```swift
// v1.x
CNIManager.sharedManager().requestImage(
    at: url,
    progress: { progress in
        progressView.progress = Float(progress)
    },
    completion: { image, error, _, _ in
        imageView.image = image
    }
)

// v2.0+
imageView.setImage(
    with: url,
    onProgress: { progress in
        progressView.progress = Float(progress)
    },
    onCompletion: { image, error, _, _ in
        // Done
    }
)

// v2.1 (with UIImage)
UIImage.load(
    from: url,
    progress: { progress in
        progressView.progress = Float(progress)
    },
    completion: { result in
        if case .success(let image) = result {
            imageView.image = image
        }
    }
)
```

### Pattern 4: Custom Configuration

```swift
// v1.x
let config = CNIConfiguration()
config.maxConcurrentDownloads = 8
CNIManager.sharedManager().configure(with: config)

// v2.0
let config = ImageDownloaderConfiguration()
config.networkConfig.maxConcurrentDownloads = 8
ImageDownloaderManager.shared.configure(config)

// v2.1 (recommended)
let config = ConfigBuilder()
    .maxConcurrentDownloads(8)
    .build()

let image = try await UIImage.load(from: url, config: config)
```

### Pattern 5: Authenticated Requests

```swift
// v1.x (not supported natively)
// Had to subclass or modify URLRequest manually

// v2.1 (native support)
let config = ConfigBuilder()
    .authenticationHandler { request in
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .customHeaders([
        "User-Agent": "MyApp/1.0"
    ])
    .build()

let image = try await UIImage.load(from: url, config: config)
```

### Pattern 6: Cache Management

```swift
// v1.x
CNIManager.sharedManager().clearCache(for: url)
CNIManager.sharedManager().clearAllCache()

// v2.0+
ImageDownloaderManager.shared.clearCache(for: url)
ImageDownloaderManager.shared.clearAllCache()

// v2.1 (same as v2.0, no changes)
ImageDownloaderManager.shared.clearCache(for: url)
ImageDownloaderManager.shared.clearAllCache()
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Build Errors After Upgrading

**Problem:**
```
Cannot find 'CNIManager' in scope
```

**Solution:**
Update import statements:
```swift
// Change this:
import CNI

// To this:
import ImageDownloader
```

#### Issue 2: Async/Await Errors

**Problem:**
```
'async' call in a function that does not support concurrency
```

**Solution:**
Wrap in Task:
```swift
Task {
    let image = try await UIImage.load(from: url)
    imageView.image = image
}
```

#### Issue 3: Config Not Applied

**Problem:**
Injectable config not working

**Solution:**
Make sure you're passing config to the method:
```swift
// Wrong - doesn't use your config
let image = try await UIImage.load(from: url)

// Correct - uses your config
let image = try await UIImage.load(from: url, config: myConfig)
```

#### Issue 4: Objective-C Compatibility

**Problem:**
Can't use new v2.1 features from Objective-C

**Solution:**
Some v2.1 features are Swift-only. Use v2.0 API from Objective-C:
```objc
// This works
[[ImageDownloaderManager shared] requestImageAt:url
    completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
        imageView.image = image;
    }];

// This is Swift-only
// let image = try await UIImage.load(from: url, config: config)
```

---

## Testing Your Migration

### Checklist

- [ ] All imports updated
- [ ] Class names updated
- [ ] Build succeeds without errors
- [ ] Basic image loading works
- [ ] Progress tracking works (if used)
- [ ] Cache management works
- [ ] Custom configuration works (if used)
- [ ] Authenticated requests work (if used)
- [ ] SwiftUI integration works (if used)
- [ ] Objective-C code still compiles (if used)

### Test Cases

```swift
class MigrationTests: XCTestCase {
    func testBasicLoading() async throws {
        let url = URL(string: "https://example.com/image.jpg")!
        let image = try await UIImage.load(from: url)
        XCTAssertNotNil(image)
    }

    func testWithConfig() async throws {
        let url = URL(string: "https://example.com/image.jpg")!
        let image = try await UIImage.load(from: url, config: FastConfig.shared)
        XCTAssertNotNil(image)
    }

    func testCacheClearing() {
        let url = URL(string: "https://example.com/image.jpg")!
        ImageDownloaderManager.shared.clearCache(for: url)
        XCTAssertEqual(ImageDownloaderManager.shared.cacheSizeHigh(), 0)
    }
}
```

---

## Need Help?

- **Documentation**: [Complete Documentation](../DOCUMENTATION.md)
- **Examples**: [Usage Examples](EXAMPLES.md)
- **Issues**: [GitHub Issues](https://github.com/ductranprof99/Image-Downloader/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ductranprof99/Image-Downloader/discussions)

---

**Migration Guide Version:** 1.0
**Last Updated:** 2025-01-06
**Covers:** v1.x → v2.0 → v2.1
