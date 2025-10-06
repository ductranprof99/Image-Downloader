# Configuration

Configure ImageDownloader behavior globally or per-request.

## Overview

ImageDownloader supports both global configuration at app launch and per-request configuration. Use ``ImageDownloaderConfiguration`` for type-safe Swift configuration or ``IDConfiguration`` for Objective-C.

## Global Configuration

Configure once at app launch for optimal performance:

```swift
import ImageDownloader

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Configure ImageDownloader
        let config = ImageDownloaderConfiguration(
            maxConcurrentDownloads: 6,
            timeout: 30,
            highCachePriority: 100,
            lowCachePriority: 200,
            shouldSaveToStorage: true
        )

        ImageDownloaderManager.shared.configure(config)

        return true
    }
}
```

## Predefined Configurations

Use built-in presets for common scenarios:

### Default Configuration

```swift
ImageDownloaderManager.shared.configure(.default)
// - 4 concurrent downloads
// - 50 high priority cache items
// - 100 low priority cache items
// - PNG compression
```

### High Performance

```swift
ImageDownloaderManager.shared.configure(.highPerformance)
// - 8 concurrent downloads
// - 100 high priority cache items
// - 200 low priority cache items
// - Optimized for photo-heavy apps
```

### Low Memory

```swift
ImageDownloaderManager.shared.configure(.lowMemory)
// - 2 concurrent downloads
// - 20 high priority cache items
// - 50 low priority cache items
// - Optimized for memory-constrained devices
```

## Configuration Options

### Network Settings

- **maxConcurrentDownloads**: Maximum parallel downloads (default: 4)
- **timeout**: Request timeout in seconds (default: 30)

### Cache Settings

- **highCachePriority**: High priority cache limit (default: 50)
- **lowCachePriority**: Low priority cache limit (default: 100)

### Storage Settings

- **storagePath**: Custom storage path (nil = default Caches directory)
- **shouldSaveToStorage**: Auto-save to disk (default: true)

### Advanced Settings

- **enableDebugLogging**: Enable debug logs (default: false)
- **enableRetry**: Retry failed downloads (default: false)
- **retryAttempts**: Number of retry attempts (default: 3)

## Per-Request Configuration

Override global settings for specific requests:

```swift
let result = try await ImageDownloaderManager.shared.requestImage(
    at: url,
    priority: .high,              // Override priority
    shouldSaveToStorage: false    // Override storage behavior
)
```

## Accessing Current Configuration

```swift
let config = ImageDownloaderManager.shared.configuration
print("Max concurrent: \(config.maxConcurrentDownloads)")
print("Compression: \(config.compressionProvider.name)")
```

## Objective-C Configuration

```objc
@import ImageDownloader;

// Use predefined configuration
[[ImageDownloaderManager shared] configure:[IDConfiguration defaultConfiguration]];

// Or customize
IDConfiguration *config = [[IDConfiguration alloc] init];
config.maxConcurrentDownloads = 6;
config.highCachePriority = 100;
config.shouldSaveToStorage = YES;

[[ImageDownloaderManager shared] configure:config];
```

## Topics

### Configuration Types

- ``ImageDownloaderConfiguration``
- ``IDConfiguration``

### Related

- <doc:Customization>
- <doc:CompressionProviders>
- <doc:StorageProviders>
