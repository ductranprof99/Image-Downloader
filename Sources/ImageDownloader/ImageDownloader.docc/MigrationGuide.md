# Migration Guide

Migrate from version 1.x (Objective-C) to 2.0+ (Swift).

## Overview

Version 2.0 represents a complete rewrite in Swift with async/await support. This guide helps you migrate from the legacy Objective-C API.

## Breaking Changes

### Package Name

**Before (v1.x):**
```swift
import CNI
import CNIUIKit
```

**After (v2.0+):**
```swift
import ImageDownloader
import ImageDownloaderUI
```

### Class Names

| v1.x (Objective-C) | v2.0+ (Swift) |
|-------------------|---------------|
| `CNIManager` | `ImageDownloaderManager` |
| `CNIImageView` | `AsyncImageView` |
| `CNIResourcePriority` | `ResourcePriority` |
| `CNIConfiguration` | `ImageDownloaderConfiguration` |
| `CustomNetworkImageView` | `NetworkImageView` |

### API Changes

#### Manager Access

**Before:**
```swift
CNIManager.sharedManager()
```

**After:**
```swift
ImageDownloaderManager.shared
```

#### Request Image

**Before (Completion Handler):**
```swift
CNIManager.sharedManager().requestImage(
    at: url,
    priority: .high,
    shouldSaveToStorage: true,
    progress: { progress in },
    completion: { image, error, fromCache, fromStorage in }
)
```

**After (Async/Await - Recommended):**
```swift
let result = try await ImageDownloaderManager.shared.requestImage(
    at: url,
    priority: .high
)
imageView.image = result.image
```

**After (Completion Handler - Still Supported):**
```swift
ImageDownloaderManager.shared.requestImage(at: url) { image, error, fromCache, fromStorage in
    imageView.image = image
}
```

## Migration Steps

### Step 1: Update Package Dependencies

Update your `Package.swift` or Xcode package reference:

```swift
// Old
.package(url: "https://github.com/yourorg/CNI.git", from: "1.0.0")

// New
.package(url: "https://github.com/ductranprof99/ImageDownloaderController.git", from: "2.0.0")
```

### Step 2: Update Imports

```swift
// Replace all imports
import CNI              → import ImageDownloader
import CNIUIKit         → import ImageDownloaderUI
import CNIComponentKit  → import ImageDownloaderComponentKit
```

### Step 3: Update Class Names

Use Xcode's Find & Replace:
- `CNIManager` → `ImageDownloaderManager`
- `CNIImageView` → `AsyncImageView`
- `CustomNetworkImageView` → `NetworkImageView`

### Step 4: Update Configuration

**Before:**
```swift
CNIManager.sharedManager().configure(
    withMaxConcurrentDownloads: 6,
    highCachePriority: 100,
    lowCachePriority: 200,
    storagePath: nil
)
```

**After:**
```swift
let config = ImageDownloaderConfiguration(
    maxConcurrentDownloads: 6,
    highCachePriority: 100,
    lowCachePriority: 200
)
ImageDownloaderManager.shared.configure(config)
```

### Step 5: Adopt Async/Await (Optional but Recommended)

**Before:**
```swift
manager.requestImage(at: url) { image, error, fromCache, fromStorage in
    if let image = image {
        self.imageView.image = image
    }
}
```

**After:**
```swift
Task {
    do {
        let result = try await manager.requestImage(at: url)
        imageView.image = result.image
    } catch {
        handleError(error)
    }
}
```

## Objective-C Migration

If you're using Objective-C, minimal changes are needed:

**Before (v1.x):**
```objc
@import CNI;

[[CNIManager sharedManager] requestImageAtURL:url
                                    completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    self.imageView.image = image;
}];
```

**After (v2.0+):**
```objc
@import ImageDownloader;

[[ImageDownloaderManager shared] requestImageAt:url
                                     completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    self.imageView.image = image;
}];
```

## New Features in 2.0

- ✅ **Async/Await** - Modern Swift concurrency
- ✅ **Customization** - Protocol-based providers
- ✅ **JPEG Compression** - Save 50-80% disk space
- ✅ **Hierarchical Storage** - Better file organization
- ✅ **Typed Errors** - `ImageDownloaderError` enum
- ✅ **Result Types** - `ImageResult` struct

## Compatibility

- **Minimum iOS:** 13.0 (up from 12.0)
- **Minimum macOS:** 10.15 (up from 10.14)
- **Swift:** 5.9+ required
- **Xcode:** 14.0+ required

## Gradual Migration

You can migrate gradually by keeping completion handlers initially:

```swift
// Phase 1: Just update names and imports
ImageDownloaderManager.shared.requestImage(at: url) { image, error, _, _ in
    self.imageView.image = image
}

// Phase 2: Adopt async/await later
Task {
    let result = try await ImageDownloaderManager.shared.requestImage(at: url)
    imageView.image = result.image
}
```

## Troubleshooting

**Issue:** Build errors after updating
**Solution:** Clean build folder (Cmd+Shift+K) and rebuild

**Issue:** Old cached images not loading
**Solution:** Images remain compatible. Clear cache if needed:
```swift
ImageDownloaderManager.shared.clearAllCache()
```

**Issue:** Missing symbols
**Solution:** Ensure you're importing the correct module (`ImageDownloader` not `CNI`)

## Support

For migration issues, see:
- <doc:GettingStarted>
- <doc:Configuration>
- [GitHub Issues](https://github.com/ductranprof99/ImageDownloaderController/issues)
