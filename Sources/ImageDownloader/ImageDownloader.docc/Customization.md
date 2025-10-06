# Customization

Customize how images are identified, stored, and compressed.

## Overview

ImageDownloader uses a protocol-based architecture that allows you to customize three key aspects:

1. **Resource Identification** - How URLs are converted to unique identifiers
2. **Storage Paths** - Where and how files are organized on disk
3. **Compression** - How images are compressed for storage

All customization is done through providers that implement simple protocols.

## Quick Example

```swift
import ImageDownloader

// Use JPEG compression to save 70% disk space
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)

ImageDownloaderManager.shared.configure(config)
```

## Compression Customization

### JPEG Compression (Recommended for Photos)

Save 50-80% disk space with JPEG compression:

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)
```

**Quality Guide:**
- `1.0` - Maximum quality, minimal compression
- `0.8` - Recommended (good balance)
- `0.6` - High compression, some artifacts
- `0.4` - Maximum compression, poor quality

### Adaptive Compression (Smart Selection)

Automatically choose PNG or JPEG based on image size:

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: AdaptiveCompressionProvider(
        sizeThresholdMB: 1.0,  // Use JPEG if PNG > 1MB
        jpegQuality: 0.85
    )
)
```

**How it works:**
1. Compresses as PNG first
2. If PNG size exceeds threshold, re-compresses as JPEG
3. Stores the smaller result

### PNG Compression (Default)

Lossless compression, larger file sizes:

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: PNGCompressionProvider()
)
```

## Storage Path Customization

### Flat Storage (Default)

All files in a single directory:

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: FlatStoragePathProvider()
)

// Result: ImageDownloaderStorage/abc123_image.png
```

### Domain-Based Hierarchy

Organize by domain for better file system performance:

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DomainHierarchicalPathProvider()
)

// Result: ImageDownloaderStorage/example.com/abc123.png
```

**Benefits:**
- Better performance with 1000+ images
- Easy to debug by source
- Cleaner file organization

### Date-Based Hierarchy

Organize by download date:

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DateHierarchicalPathProvider()
)

// Result: ImageDownloaderStorage/2025/10/06/abc123.png
```

**Benefits:**
- Time-based analysis
- Easy cleanup of old images
- Archival use cases

## Identifier Customization

### MD5 (Default)

Fast, compatible, good for most use cases:

```swift
let config = ImageDownloaderConfiguration(
    identifierProvider: MD5IdentifierProvider()
)

// Result: d41d8cd98f00b204e9800998ecf8427e
```

### SHA256 (More Secure)

Better security and collision resistance:

```swift
let config = ImageDownloaderConfiguration(
    identifierProvider: SHA256IdentifierProvider()
)

// Result: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Combined Customization

Mix and match providers for your use case:

### Photo-Heavy App

```swift
let config = ImageDownloaderConfiguration(
    maxConcurrentDownloads: 8,
    identifierProvider: SHA256IdentifierProvider(),
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: JPEGCompressionProvider(quality: 0.85)
)
```

### Space-Constrained App

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.7)
)
```

### Large-Scale App (10,000+ Images)

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: AdaptiveCompressionProvider()
)
```

## Creating Custom Providers

Implement the protocols to create your own providers:

```swift
import ImageDownloader
import CryptoKit

struct CustomIdentifierProvider: ResourceIdentifierProvider {
    func identifier(for url: URL) -> String {
        // Your custom logic here
        let urlString = url.absoluteString
        let hash = SHA512.hash(data: Data(urlString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Use it
let config = ImageDownloaderConfiguration(
    identifierProvider: CustomIdentifierProvider()
)
```

## Objective-C Support

All built-in providers have Objective-C wrappers:

```objc
@import ImageDownloader;

// JPEG compression
IDJPEGCompressionProvider *jpeg = [[IDJPEGCompressionProvider alloc] initWithQuality:0.8];

// Domain hierarchy
IDDomainHierarchicalPathProvider *paths = [[IDDomainHierarchicalPathProvider alloc] init];

// Apply
IDConfiguration *config = [[IDConfiguration alloc] init];
config.compressionProvider = jpeg;
config.pathProvider = paths;

[[ImageDownloaderManager shared] configure:config];
```

## Performance Impact

| Configuration | Disk Usage | File System Speed | Best For |
|--------------|-----------|------------------|----------|
| PNG + Flat | 100% | Good (<1K files) | Icons, small images |
| JPEG 0.8 + Flat | 30% | Good (<1K files) | Photos, medium apps |
| Adaptive + Domain | 40% | Excellent (10K+ files) | **Recommended** |
| JPEG 0.6 + Domain | 25% | Excellent (10K+ files) | Maximum compression |

## Topics

### Protocols

- ``ResourceIdentifierProvider``
- ``StoragePathProvider``
- ``ImageCompressionProvider``

### Related Articles

- <doc:CompressionProviders>
- <doc:StorageProviders>
- <doc:Configuration>
