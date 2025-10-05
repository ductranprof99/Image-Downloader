# CNI - Custom Network Image Library

A powerful, production-ready iOS image loading library with advanced caching, storage, and multi-framework support.

## Features

✨ **Core Features:**
- Two-tier memory cache (high/low priority)
- Persistent disk storage
- Concurrent download management with priority queuing
- Observer pattern for global notifications
- Progress tracking
- MD5-based resource identification

📦 **Multi-Framework Support:**
- **CNI** - Core library (framework-agnostic)
- **CNIUIKit** - UIKit adapter with `CNIImageView` and category
- **CNIComponentKit** - ComponentKit integration
- **CNISwiftUI** - SwiftUI support (coming soon)

🎯 **Production Ready:**
- Memory-efficient two-tier caching
- Automatic cache cleanup
- Thread-safe operations
- Request deduplication (planned)
- Retry mechanism (planned)

## Installation

### Swift Package Manager

Add CNI to your project via Xcode:

1. File → Add Packages
2. Enter repository URL
3. Select version/branch
4. Choose targets you need:
   - `CNI` - Core library (required)
   - `CNIUIKit` - UIKit support
   - `CNIComponentKit` - ComponentKit support

Or add to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/yourorg/CNI.git", from: "1.0.0")
]
```

## Quick Start

### UIKit - Using CNIImageView

```objc
#import <CNIUIKit/CNIImageView.h>

CNIImageView *imageView = [[CNIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
imageView.placeholderImage = [UIImage imageNamed:@"placeholder"];
imageView.priority = CNIResourcePriorityHigh;
imageView.shouldSaveToStorage = YES;

// With progress tracking
imageView.onProgress = ^(CGFloat progress) {
  NSLog(@"Loading: %.0f%%", progress * 100);
};

// With completion callback
imageView.onCompletion = ^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
  if (image) {
    NSLog(@"Loaded from %@", fromCache ? @"cache" : @"network");
  }
};

[imageView loadImageFromURL:[NSURL URLWithString:@"https://example.com/image.jpg"]];
```

### UIKit - Using UIImageView Category

```objc
#import <CNIUIKit/UIImageView+CNI.h>

UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

// Simple usage
[imageView cni_setImageWithURL:[NSURL URLWithString:@"https://example.com/image.jpg"]];

// With placeholder
[imageView cni_setImageWithURL:[NSURL URLWithString:@"https://example.com/image.jpg"]
                   placeholder:[UIImage imageNamed:@"placeholder"]];

// With priority and progress
[imageView cni_setImageWithURL:[NSURL URLWithString:@"https://example.com/image.jpg"]
                   placeholder:[UIImage imageNamed:@"placeholder"]
                      priority:CNIResourcePriorityHigh
                    onProgress:^(CGFloat progress) {
                      NSLog(@"Progress: %.0f%%", progress * 100);
                    }];
```

### ComponentKit - Using CustomNetworkImageView

```objc
#import <CNIComponentKit/CustomNetworkImageView.h>

CKComponent *imageComponent = [CustomNetworkImageView
  newWithURL:@"https://example.com/image.jpg"
        size:{.width = CKRelativeDimension::Percent(1), .height = CKRelativeDimension::Points(200)}
     options:{
       .placeholder = [UIImage imageNamed:@"placeholder"],
       .maskType = CustomImageMaskTypeCircle,
       .cachePriority = CNIResourcePriorityHigh,
       .shouldSaveToStorage = YES,
       .progressOverlay = YES,
       .onProgress = ^(CGFloat progress) {
         NSLog(@"Loading: %.0f%%", progress * 100);
       },
       .onCompletion = ^(UIImage *image, NSError *error, BOOL fromCache) {
         NSLog(@"Image loaded");
       }
     }
  attributes:{}
];
```

### Core API - Direct CNIManager Usage

```objc
#import <CNI/CNI.h>

[[CNIManager sharedManager] requestImageAtURL:[NSURL URLWithString:@"https://example.com/image.jpg"]
                                     priority:CNIResourcePriorityHigh
                          shouldSaveToStorage:YES
                                     progress:^(CGFloat progress) {
                                       NSLog(@"Progress: %.0f%%", progress * 100);
                                     }
                                   completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
                                     if (image) {
                                       NSLog(@"Got image from %@", fromCache ? @"cache" : (fromStorage ? @"storage" : @"network"));
                                     }
                                   }
                                       caller:self];
```

## Configuration

### Global Configuration

```objc
[[CNIManager sharedManager] configureWithMaxConcurrentDownloads:6
                                              highCachePriority:100
                                               lowCachePriority:200
                                                    storagePath:nil]; // nil = default Documents directory
```

### Cache Management

```objc
// Clear low priority cache only
[[CNIManager sharedManager] clearLowPriorityCache];

// Clear all memory cache
[[CNIManager sharedManager] clearAllCache];

// Clear disk storage
[[CNIManager sharedManager] clearStorage:^(BOOL success) {
  NSLog(@"Storage cleared: %@", success ? @"YES" : @"NO");
}];

// Hard reset (clear everything)
[[CNIManager sharedManager] hardReset];
```

### Statistics

```objc
NSUInteger highCacheCount = [[CNIManager sharedManager] cacheSizeHigh];
NSUInteger lowCacheCount = [[CNIManager sharedManager] cacheSizeLow];
NSUInteger storageBytes = [[CNIManager sharedManager] storageSizeBytes];
NSUInteger activeDownloads = [[CNIManager sharedManager] activeDownloadsCount];
NSUInteger queuedDownloads = [[CNIManager sharedManager] queuedDownloadsCount];

NSLog(@"Cache: %lu high, %lu low | Storage: %lu bytes | Downloads: %lu active, %lu queued",
      highCacheCount, lowCacheCount, storageBytes, activeDownloads, queuedDownloads);
```

## Observer Pattern

Observe global image loading events:

```objc
#import <CNI/CNIObserver.h>

@interface MyObserver : NSObject <CNIObserver>
@end

@implementation MyObserver

- (void)imageDidStartLoading:(NSURL *)URL {
  NSLog(@"Started loading: %@", URL);
}

- (void)imageDidFinishLoading:(NSURL *)URL
                        image:(UIImage *)image
                    fromCache:(BOOL)fromCache
                  fromStorage:(BOOL)fromStorage {
  NSLog(@"Finished loading: %@ (from %@)", URL, fromCache ? @"cache" : @"network");
}

- (void)imageDidFailLoading:(NSURL *)URL error:(NSError *)error {
  NSLog(@"Failed loading: %@ - %@", URL, error.localizedDescription);
}

@end

// Register observer
MyObserver *observer = [[MyObserver alloc] init];
[[CNIManager sharedManager] addObserver:observer];

// Unregister when done
[[CNIManager sharedManager] removeObserver:observer];
```

## Architecture

### CNI Core

```
CNIManager (Coordinator)
├── CNICacheAgent (Two-tier memory cache)
├── CNIStorageAgent (Disk persistence)
├── CNINetworkAgent (Concurrent downloads)
└── CNIObserver (Event notifications)
```

### Adapters

- **CNIUIKit**: `CNIImageView` + `UIImageView+CNI` category
- **CNIComponentKit**: `CustomNetworkImageView` + `ComponentImageDownloader`
- **CNISwiftUI**: `CNIAsyncImage` (planned)

## Roadmap

### Version 1.1.0
- [ ] Protocol-based multi-framework adapter system
- [ ] Configuration inheritance (global → request → runtime)
- [ ] Request deduplication

### Version 1.2.0
- [ ] Retry mechanism with exponential backoff
- [ ] Custom headers/authentication support
- [ ] Bandwidth throttling
- [ ] Progressive image loading
- [ ] WebP/AVIF format support

### Version 1.3.0
- [ ] SwiftUI adapter (CNIAsyncImage)
- [ ] Network reachability monitoring
- [ ] Request interceptor pattern

## Requirements

- iOS 13.0+
- macOS 10.15+
- Xcode 14.0+
- Swift 5.9+ (for SPM)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.

## Support

- 📖 Documentation: See `/docs` directory
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions

---

**CNI** - Built for production, designed for performance.
