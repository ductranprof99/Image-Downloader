# ImageDownloader Customization Examples

Complete examples for customizing ImageDownloader behavior using providers.

## Table of Contents
- [Quick Start](#quick-start)
- [Compression Providers](#compression-providers)
- [Storage Path Providers](#storage-path-providers)
- [Identifier Providers](#identifier-providers)
- [Combined Customizations](#combined-customizations)
- [Objective-C Examples](#objective-c-examples)

---

## Quick Start

### Default Behavior (No Customization)

```swift
import ImageDownloader

// Use default configuration
// - MD5 identifier
// - Flat storage (all files in one directory)
// - PNG compression (lossless)
ImageDownloaderManager.shared.configure(.default)

let result = try await ImageDownloaderManager.shared.requestImage(at: url)
```

---

## Compression Providers

### JPEG Compression (Save 50-80% Disk Space)

```swift
import ImageDownloader

// Configure with JPEG compression
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)
ImageDownloaderManager.shared.configure(config)

// All downloaded images will now be stored as JPEG
let result = try await ImageDownloaderManager.shared.requestImage(at: url)
```

**Benefits:**
- 50-80% smaller file sizes
- Faster disk writes
- Good for photos and large images
- Quality parameter: 0.0 (max compression) to 1.0 (max quality)

**Recommended Quality Settings:**
- `0.95` - Nearly lossless, minimal compression
- `0.8` - Good balance (recommended)
- `0.6` - High compression, visible artifacts
- `0.4` - Maximum compression, poor quality

### Adaptive Compression (Smart PNG/JPEG Selection)

```swift
import ImageDownloader

// Automatically choose PNG or JPEG based on size
let config = ImageDownloaderConfiguration(
    compressionProvider: AdaptiveCompressionProvider(
        sizeThresholdMB: 1.0,  // Switch to JPEG if PNG > 1MB
        jpegQuality: 0.85
    )
)
ImageDownloaderManager.shared.configure(config)
```

**How It Works:**
1. Compresses image as PNG
2. If PNG size > threshold, re-compresses as JPEG
3. Stores the smaller result

**Best For:**
- Mixed content (small icons + large photos)
- Optimizing storage without manual tuning
- Apps with varying image sizes

---

## Storage Path Providers

### Flat Storage (Default)

```swift
// All images in single directory
// Files: abc123_image.png, def456_photo.jpg

let config = ImageDownloaderConfiguration(
    pathProvider: FlatStoragePathProvider()
)
```

**Structure:**
```
ImageDownloaderStorage/
├── abc123_image1.png
├── def456_image2.png
└── 789xyz_image3.png
```

**Best For:**
- Small to medium image collections (<1000 files)
- Simple use cases
- Backward compatibility

### Domain-Based Hierarchy

```swift
// Organize by domain
let config = ImageDownloaderConfiguration(
    pathProvider: DomainHierarchicalPathProvider()
)
```

**Structure:**
```
ImageDownloaderStorage/
├── example.com/
│   ├── abc123.png
│   └── def456.png
├── cdn.myapp.com/
│   └── 789xyz.jpg
└── unknown/
    └── orphan.png
```

**Best For:**
- Multiple image sources
- Debugging/troubleshooting
- Large image collections (1000+ files)
- Better file system performance

### Date-Based Hierarchy

```swift
// Organize by download date
let config = ImageDownloaderConfiguration(
    pathProvider: DateHierarchicalPathProvider()
)
```

**Structure:**
```
ImageDownloaderStorage/
├── 2025/
│   ├── 10/
│   │   ├── 06/
│   │   │   ├── abc123.png
│   │   │   └── def456.png
│   │   └── 07/
│   │       └── 789xyz.png
└── 2025/
    └── 11/
        └── 01/
            └── image.png
```

**Best For:**
- Time-based analysis
- Easy cleanup of old images
- Archival use cases
- Debugging based on timeline

---

## Identifier Providers

### MD5 Identifier (Default)

```swift
let config = ImageDownloaderConfiguration(
    identifierProvider: MD5IdentifierProvider()
)
```

**Characteristics:**
- Fast computation
- 32-character hex string
- Widely compatible
- Good for most use cases

**Example:** `d41d8cd98f00b204e9800998ecf8427e`

### SHA256 Identifier (More Secure)

```swift
@available(iOS 13.0, *)
let config = ImageDownloaderConfiguration(
    identifierProvider: SHA256IdentifierProvider()
)
```

**Characteristics:**
- More secure than MD5
- 64-character hex string
- Better collision resistance
- Recommended for new projects

**Example:** `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

---

## Combined Customizations

### Example 1: Maximum Space Savings

```swift
import ImageDownloader

// Optimize for minimal disk usage
let config = ImageDownloaderConfiguration(
    maxConcurrentDownloads: 4,
    identifierProvider: MD5IdentifierProvider(),
    pathProvider: FlatStoragePathProvider(),
    compressionProvider: JPEGCompressionProvider(quality: 0.75)
)

ImageDownloaderManager.shared.configure(config)
```

**Use Case:** Apps with limited storage, user-generated content

###Example 2: Organized Large-Scale Storage

```swift
import ImageDownloader

// Organize 10,000+ images efficiently
let config = ImageDownloaderConfiguration(
    identifierProvider: SHA256IdentifierProvider(),
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: AdaptiveCompressionProvider(
        sizeThresholdMB: 2.0,
        jpegQuality: 0.85
    )
)

ImageDownloaderManager.shared.configure(config)
```

**Use Case:** Social media apps, content aggregators, news apps

### Example 3: Debug-Friendly Setup

```swift
import ImageDownloader

// Easy to debug and troubleshoot
let config = ImageDownloaderConfiguration(
    identifierProvider: MD5IdentifierProvider(),
    pathProvider: DateHierarchicalPathProvider(),
    compressionProvider: PNGCompressionProvider(),
    enableDebugLogging: true
)

ImageDownloaderManager.shared.configure(config)
```

**Use Case:** Development, QA testing, troubleshooting

### Example 4: High-Performance Photo App

```swift
import ImageDownloader

// Optimized for photo-heavy apps
let config = ImageDownloaderConfiguration(
    maxConcurrentDownloads: 8,
    highCachePriority: 100,
    lowCachePriority: 200,
    identifierProvider: SHA256IdentifierProvider(),
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: JPEGCompressionProvider(quality: 0.90)
)

ImageDownloaderManager.shared.configure(config)
```

**Use Case:** Photo galleries, Instagram-like apps, camera apps

---

## Objective-C Examples

### JPEG Compression (Objective-C)

```objc
@import ImageDownloader;

// Create JPEG compression provider
IDJPEGCompressionProvider *jpegProvider = [[IDJPEGCompressionProvider alloc] initWithQuality:0.8];

// Create configuration
IDConfiguration *config = [[IDConfiguration alloc] init];
config.compressionProvider = jpegProvider;

// Apply configuration
[[ImageDownloaderManager shared] configure:config];
```

### Domain Hierarchy (Objective-C)

```objc
@import ImageDownloader;

// Create domain hierarchical path provider
IDDomainHierarchicalPathProvider *pathProvider = [[IDDomainHierarchicalPathProvider alloc] init];

// Create configuration
IDConfiguration *config = [[IDConfiguration alloc] init];
config.pathProvider = pathProvider;

// Apply configuration
[[ImageDownloaderManager shared] configure:config];
```

### Combined (Objective-C)

```objc
@import ImageDownloader;

// Create providers
IDDomainHierarchicalPathProvider *pathProvider = [[IDDomainHierarchicalPathProvider alloc] init];
IDAdaptiveCompressionProvider *compressionProvider = [[IDAdaptiveCompressionProvider alloc] initWithSizeThresholdMB:1.5 jpegQuality:0.85];

// Create configuration
IDConfiguration *config = [[IDConfiguration alloc] init];
config.maxConcurrentDownloads = 6;
config.pathProvider = pathProvider;
config.compressionProvider = compressionProvider;

// Apply configuration
[[ImageDownloaderManager shared] configure:config];
```

---

## Custom Provider Implementation

### Creating a Custom Identifier Provider

```swift
import ImageDownloader
import CryptoKit

// Custom provider that uses SHA512
@available(iOS 13.0, *)
struct SHA512IdentifierProvider: ResourceIdentifierProvider {
    func identifier(for url: URL) -> String {
        let urlString = url.absoluteString
        let hash = SHA512.hash(data: Data(urlString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Usage
let config = ImageDownloaderConfiguration(
    identifierProvider: SHA512IdentifierProvider()
)
```

### Creating a Custom Path Provider

```swift
import ImageDownloader

// Custom provider that organizes by image type
struct ImageTypePathProvider: StoragePathProvider {
    func path(for url: URL, identifier: String) -> String {
        let category = categorize(url: url)
        let ext = url.pathExtension.isEmpty ? "png" : url.pathExtension
        return "\(category)/\(identifier).\(ext)"
    }

    func directoryStructure(for url: URL) -> [String] {
        return [categorize(url: url)]
    }

    private func categorize(url: URL) -> String {
        let path = url.path.lowercased()
        if path.contains("avatar") || path.contains("profile") {
            return "avatars"
        } else if path.contains("thumb") || path.contains("preview") {
            return "thumbnails"
        } else if path.contains("photo") || path.contains("image") {
            return "photos"
        } else {
            return "other"
        }
    }
}

// Usage
let config = ImageDownloaderConfiguration(
    pathProvider: ImageTypePathProvider()
)
```

---

## Performance Comparison

| Configuration | Storage Size | File System Performance | Best For |
|---------------|-------------|------------------------|----------|
| PNG + Flat | 100% (baseline) | Good (<1000 files) | Small apps, icons |
| JPEG 0.8 + Flat | 30-40% | Good (<1000 files) | Medium apps, photos |
| JPEG 0.6 + Flat | 20-30% | Good (<1000 files) | High compression needed |
| PNG + Domain | 100% | Excellent (10k+ files) | Large organized collections |
| Adaptive + Domain | 40-50% | Excellent (10k+ files) | Production apps (recommended) |
| JPEG 0.8 + Date | 30-40% | Excellent (10k+ files) | Time-based archival |

---

## Migration Guide

### Migrating from Default to Custom

**Step 1:** Test custom configuration in development
```swift
#if DEBUG
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)
#else
let config = ImageDownloaderConfiguration.default
#endif
```

**Step 2:** Monitor storage usage
```swift
let storageBytes = ImageDownloaderManager.shared.storageSizeBytes()
print("Storage: \(storageBytes / 1024 / 1024) MB")
```

**Step 3:** Deploy to production
```swift
// Apply custom configuration to all users
let config = ImageDownloaderConfiguration(
    compressionProvider: AdaptiveCompressionProvider()
)
ImageDownloaderManager.shared.configure(config)
```

**Note:** Existing cached images remain in old format. New downloads use the new configuration.

---

## Best Practices

1. **Configure Once at App Launch**
   ```swift
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       // Configure ImageDownloader once
       ImageDownloaderManager.shared.configure(myConfig)
       return true
   }
   ```

2. **Use Adaptive Compression for Production**
   - Automatically optimizes based on image size
   - Good balance between quality and storage

3. **Use Hierarchical Storage for Large Apps**
   - Better file system performance with 1000+ images
   - Easier debugging and maintenance

4. **Monitor Storage Usage**
   - Periodically check `storageSizeBytes()`
   - Implement cache cleanup if needed

5. **Test Different Configurations**
   - Measure storage impact
   - Check image quality
   - Monitor performance

---

## Troubleshooting

**Q: Images look blurry after switching to JPEG**
A: Increase JPEG quality: `JPEGCompressionProvider(quality: 0.9)`

**Q: Storage not saving space**
A: Ensure configuration is applied before downloads: `configure()` at app launch

**Q: Can't find images after changing path provider**
A: Old images remain in old location. Clear storage or support both paths.

**Q: Objective-C configuration not working**
A: Make sure to set providers on IDConfiguration, not ImageDownloaderConfiguration

---

## Resources

- [USAGE_GUIDE.md](USAGE_GUIDE.md) - General usage guide
- [CUSTOMIZATION_DESIGN.md](CUSTOMIZATION_DESIGN.md) - Architecture and design
- [README.md](README.md) - Quick start and overview

---

**Need more customization?** Create custom providers by conforming to:
- `ResourceIdentifierProvider`
- `StoragePathProvider`
- `ImageCompressionProvider`
