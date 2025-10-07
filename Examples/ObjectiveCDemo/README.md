# Objective-C Demo - ImageDownloader

Complete Objective-C integration examples for ImageDownloader.

## 📱 Overview

This demo showcases **full Objective-C compatibility** for ImageDownloader library, proving it can be seamlessly integrated into legacy Objective-C projects.

## ✅ Objective-C Compatibility

ImageDownloader is **100% Objective-C compatible** with:
- ✅ All core APIs exposed to Objective-C
- ✅ Completion handler-based async operations
- ✅ NSObject-based configuration classes
- ✅ UIImageView category extensions
- ✅ Proper memory management
- ✅ Thread-safe operations

## 🚀 Quick Start

### 1. Import the Framework

```objc
@import ImageDownloader;
```

### 2. Basic Usage

```objc
// Using UIImageView extension (Recommended)
NSURL *url = [NSURL URLWithString:@"https://example.com/image.jpg"];
UIImage *placeholder = [UIImage imageNamed:@"placeholder"];

[self.imageView setImageObjCWith:url
                     placeholder:placeholder
                        priority:ResourcePriorityHigh
                      completion:^(UIImage *image, NSError *error) {
    if (image) {
        NSLog(@"Image loaded successfully");
    } else {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}];
```

### 3. Using Manager Directly

```objc
ImageDownloaderManager *manager = [ImageDownloaderManager shared];

[manager requestImageObjCAt:url
                   priority:ResourcePriorityHigh
                   progress:^(CGFloat progress) {
    NSLog(@"Progress: %.0f%%", progress * 100);
} completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (image) {
        self.imageView.image = image;
        NSString *source = fromCache ? @"cache" : (fromStorage ? @"storage" : @"network");
        NSLog(@"Loaded from: %@", source);
    }
}];
```

## 📚 Examples

### Check if Image is Cached

```objc
NSURL *url = [NSURL URLWithString:@"https://example.com/image.jpg"];
ImageDownloaderManager *manager = [ImageDownloaderManager shared];

BOOL isCached = [manager isCachedObjCWithUrl:url];
if (isCached) {
    UIImage *cachedImage = [manager getCachedImageObjCFor:url];
    self.imageView.image = cachedImage;
}
```

### Custom Configuration

```objc
// Fast configuration (preset)
IDConfiguration *fastConfig = [IDConfiguration fastConfiguration];

// Low memory configuration (preset)
IDConfiguration *lowMemConfig = [IDConfiguration lowMemoryConfiguration];

// Custom configuration
IDConfiguration *config = [[IDConfiguration alloc] init];
config.maxConcurrentDownloads = 8;
config.timeout = 60;
config.allowsCellularAccess = YES;
config.maxRetries = 5;
config.retryBaseDelay = 1.0;
config.highPriorityLimit = 100;
config.lowPriorityLimit = 200;

// Add custom headers
config.customHeaders = @{
    @"User-Agent": @"MyApp/1.0",
    @"X-API-Key": @"your-api-key-here"
};
```

### JPEG Compression

```objc
IDJPEGCompressionProvider *jpeg = [[IDJPEGCompressionProvider alloc] initWithQuality:0.8];
NSLog(@"Using compression: %@", jpeg.name);
// Output: "JPEG (Quality: 80%)"

// Compress an image
UIImage *image = [UIImage imageNamed:@"photo"];
NSData *compressedData = [jpeg compress:image];

// Decompress
UIImage *decompressed = [jpeg decompress:compressedData];
```

### PNG Compression

```objc
IDPNGCompressionProvider *png = [[IDPNGCompressionProvider alloc] init];
NSLog(@"Using compression: %@", png.name);
// Output: "PNG (Lossless)"
```

### Domain Hierarchical Storage

```objc
IDDomainHierarchicalPathProvider *pathProvider = [[IDDomainHierarchicalPathProvider alloc] init];

NSURL *url = [NSURL URLWithString:@"https://example.com/photos/image.jpg"];
NSString *path = [pathProvider pathFor:url identifier:@"abc123"];
NSLog(@"Storage path: %@", path);
// Output: "example.com/abc123.jpg"
```

### Date Hierarchical Storage

```objc
IDDateHierarchicalPathProvider *pathProvider = [[IDDateHierarchicalPathProvider alloc] init];

NSURL *url = [NSURL URLWithString:@"https://example.com/image.jpg"];
NSString *path = [pathProvider pathFor:url identifier:@"abc123"];
NSLog(@"Storage path: %@", path);
// Output: "2025/10/07/abc123.jpg"
```

### Cache Management

```objc
ImageDownloaderManager *manager = [ImageDownloaderManager shared];

// Clear memory cache
[manager clearAllCache];

// Clear low priority cache only
[manager clearLowPriorityCache];

// Clear disk storage
[manager clearStorage:^(BOOL success) {
    if (success) {
        NSLog(@"Storage cleared");
    }
}];

// Hard reset (clear everything)
[manager hardReset];
```

### Statistics

```objc
ImageDownloaderManager *manager = [ImageDownloaderManager shared];

NSInteger highCacheCount = [manager cacheSizeHigh];
NSInteger lowCacheCount = [manager cacheSizeLow];
NSUInteger storageBytes = [manager storageSizeBytes];
NSInteger activeDownloads = [manager activeDownloadsCount];

double storageMB = (double)storageBytes / (1024.0 * 1024.0);

NSLog(@"📊 Statistics:");
NSLog(@"High priority cache: %ld images", (long)highCacheCount);
NSLog(@"Low priority cache: %ld images", (long)lowCacheCount);
NSLog(@"Storage size: %.2f MB", storageMB);
NSLog(@"Active downloads: %ld", (long)activeDownloads);
```

### Cancel Loading

```objc
// Cancel loading for a specific UIImageView
[self.imageView cancelImageLoadingObjC];
```

### Error Handling

```objc
[manager requestImageObjCAt:url
                   priority:ResourcePriorityHigh
                 completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (error) {
        switch (error.code) {
            case IDErrorCodeInvalidURL:
                NSLog(@"Invalid URL");
                break;
            case IDErrorCodeNetworkError:
                NSLog(@"Network error");
                break;
            case IDErrorCodeTimeout:
                NSLog(@"Request timed out");
                break;
            case IDErrorCodeDecodingFailed:
                NSLog(@"Could not decode image");
                break;
            case IDErrorCodeCancelled:
                NSLog(@"Download cancelled");
                break;
            case IDErrorCodeNotFound:
                NSLog(@"Image not found (404)");
                break;
            default:
                NSLog(@"Unknown error: %@", error.localizedDescription);
        }
    }
}];
```

## 🔧 Available Classes

### Configuration
- `IDConfiguration` - Main configuration class
- `IDJPEGCompressionProvider` - JPEG compression
- `IDPNGCompressionProvider` - PNG compression
- `IDDomainHierarchicalPathProvider` - Domain-based storage
- `IDDateHierarchicalPathProvider` - Date-based storage

### Results
- `IDImageResult` - Image loading result wrapper

### Enums
- `IDErrorCode` - Error code enumeration
- `ResourcePriority` - Priority levels (High/Low)

### Extensions
- `UIImageView` - Category with `setImageObjC...` methods
- `ImageDownloaderManager` - ObjC bridge methods

## 📱 UITableView/UICollectionView Integration

### Table View Cell

```objc
@interface ImageCell : UITableViewCell
@property (nonatomic, strong) UIImageView *photoImageView;
@end

@implementation ImageCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.photoImageView cancelImageLoadingObjC];
    self.photoImageView.image = nil;
}

- (void)configureWithURL:(NSURL *)url {
    UIImage *placeholder = [UIImage imageNamed:@"placeholder"];

    [self.photoImageView setImageObjCWith:url
                              placeholder:placeholder
                                 priority:ResourcePriorityLow
                               completion:nil];
}

@end
```

### Collection View Cell

```objc
@interface PhotoCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation PhotoCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView cancelImageLoadingObjC];
    self.imageView.image = nil;
}

- (void)configureWithURL:(NSURL *)url {
    [self.imageView setImageObjCWith:url
                         placeholder:[UIImage imageNamed:@"placeholder"]
                            priority:ResourcePriorityLow
                          completion:^(UIImage *image, NSError *error) {
        // Optional: handle completion
    }];
}

@end
```

## 🎯 Best Practices

### 1. Always Cancel in Cell Reuse

```objc
- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView cancelImageLoadingObjC];
}
```

### 2. Use Appropriate Priority

```objc
// High priority for visible, important images
[imageView setImageObjCWith:url placeholder:placeholder priority:ResourcePriorityHigh completion:nil];

// Low priority for thumbnails, off-screen images
[imageView setImageObjCWith:url placeholder:placeholder priority:ResourcePriorityLow completion:nil];
```

### 3. Handle Memory Warnings

```objc
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[ImageDownloaderManager shared] clearLowPriorityCache];
}
```

### 4. Use Completion Handlers on Main Thread

All completion handlers are automatically called on the main thread, so UI updates are safe:

```objc
[manager requestImageObjCAt:url priority:ResourcePriorityHigh completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    // This is already on main thread - safe to update UI
    self.imageView.image = image;
}];
```

## 📊 Configuration Presets

### Fast Configuration
```objc
IDConfiguration *config = [IDConfiguration fastConfiguration];
// - 8 concurrent downloads
// - 5 max retries
// - Large cache (100/200)
```

### Low Memory Configuration
```objc
IDConfiguration *config = [IDConfiguration lowMemoryConfiguration];
// - 2 concurrent downloads
// - 3 max retries
// - Small cache (20/30)
```

### Default Configuration
```objc
IDConfiguration *config = [IDConfiguration defaultConfiguration];
// - 4 concurrent downloads
// - 3 max retries
// - Medium cache (50/100)
```

## 🔗 Related Resources

- [Main README](../../README.md)
- [Swift Examples](../../markdown/EXAMPLES.md)
- [Architecture](../../markdown/ARCHITECTURE.md)
- [Objective-C Integration Guide](../../Sources/ImageDownloader/ImageDownloader.docc/ObjectiveCIntegration.md)

## ✅ Compatibility

- ✅ iOS 13.0+
- ✅ Objective-C 2.0
- ✅ ARC (Automatic Reference Counting)
- ✅ Thread-safe
- ✅ Production-ready

## 💡 Migration from Swift

If you're migrating from Swift code:

| Swift | Objective-C |
|-------|-------------|
| `imageView.setImage(with: url)` | `[imageView setImageObjCWith:url placeholder:nil completion:nil]` |
| `ImageDownloaderManager.shared` | `[ImageDownloaderManager shared]` |
| `manager.requestImageAsync(at: url)` | `[manager requestImageObjCAt:url priority:... completion:...]` |
| `FastConfig.shared` | `[IDConfiguration fastConfiguration]` |

## 🙏 Questions?

File an issue at [GitHub Issues](https://github.com/ductranprof99/Image-Downloader/issues)
