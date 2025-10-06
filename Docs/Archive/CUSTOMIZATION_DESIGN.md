# ImageDownloader Customization Design

## Overview
Design for customizable resource handling, storage, and compression mechanisms.

---

## 1. What Users Can Customize

### A. **Resource Identification** (How to generate unique IDs)
- Default: MD5 hash of URL
- Custom: User-defined identifier strategy
  - SHA256 hashing
  - Custom URL normalization
  - Query parameter filtering
  - Domain-specific ID extraction

**Use Case:** Different CDN URLs pointing to same image

### B. **Storage Structure** (Where/how to save files)
- Default: Flat directory with hashed filenames
- Custom: Hierarchical folder structure
  - By domain: `example.com/images/abc123.png`
  - By date: `2025/10/06/abc123.png`
  - By category: `avatars/abc123.png`
  - By size: `large/abc123.png`

**Use Case:** Organize thousands of images by source/type

### C. **File Naming** (How to name saved files)
- Default: `{hash}_{filename}.png`
- Custom: User-defined naming strategy
  - `{timestamp}_{hash}.jpg`
  - `{domain}_{id}.png`
  - Original URL structure preserved

**Use Case:** Debug-friendly filenames, file system compatibility

### D. **Compression/Decompression** (How to process image data)
- Default: PNG representation (lossless)
- Custom: Compression strategies
  - JPEG with quality control (lossy, smaller)
  - WebP support (modern, efficient)
  - HEIC support (iOS native, smallest)
  - Custom compression algorithms
  - Conditional compression (size-based)

**Use Case:** Save disk space, optimize for specific formats

### E. **Serialization Format** (How to store metadata)
- Default: No metadata
- Custom: Metadata storage
  - JSON sidecar files
  - Extended attributes
  - SQLite database
  - Custom format

**Use Case:** Store download date, source, tags, etc.

### F. **Cache Eviction Policy** (How to decide what to remove)
- Default: LRU (Least Recently Used)
- Custom: Eviction strategies
  - LFU (Least Frequently Used)
  - Size-based (largest first)
  - Age-based (oldest first)
  - Priority-based
  - Custom scoring algorithm

**Use Case:** Optimize cache based on app usage patterns

### G. **Image Processing** (Transform before storage/display)
- Default: Store original
- Custom: Processing pipeline
  - Resize to maximum dimensions
  - Convert color space
  - Apply filters
  - Generate thumbnails
  - Multi-resolution storage

**Use Case:** Reduce memory usage, consistent sizing

---

## 2. Protocol-Based Architecture

### Core Protocols

```swift
/// Generates unique identifiers for resources
public protocol ResourceIdentifierProvider {
    func identifier(for url: URL) -> String
}

/// Determines storage path for resources
public protocol StoragePathProvider {
    func path(for url: URL, identifier: String) -> String
    func directoryStructure(for url: URL) -> [String]  // Subdirectories
}

/// Handles image compression/decompression
public protocol ImageCompressionProvider {
    func compress(_ image: UIImage) -> Data?
    func decompress(_ data: Data) -> UIImage?
    var fileExtension: String { get }
}

/// Manages resource metadata
public protocol ResourceMetadataProvider {
    func metadata(for url: URL) -> [String: Any]?
    func saveMetadata(_ metadata: [String: Any], for url: URL)
    func clearMetadata(for url: URL)
}

/// Decides cache eviction strategy
public protocol CacheEvictionPolicy {
    func shouldEvict(resource: ResourceModel, currentCacheSize: Int, limit: Int) -> Bool
    func scoreForEviction(resource: ResourceModel) -> Double
}

/// Processes images before storage/display
public protocol ImageProcessor {
    func process(_ image: UIImage, for url: URL) -> UIImage
    func shouldProcess(for url: URL) -> Bool
}
```

---

## 3. Default Implementations

### MD5 Identifier Provider (Default)
```swift
public class MD5IdentifierProvider: ResourceIdentifierProvider {
    public func identifier(for url: URL) -> String {
        let urlString = url.absoluteString
        let hash = Insecure.MD5.hash(data: Data(urlString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
```

### Flat Storage Path Provider (Default)
```swift
public class FlatStoragePathProvider: StoragePathProvider {
    public func path(for url: URL, identifier: String) -> String {
        let filename = "\(identifier)_\(url.lastPathComponent)"
        return filename
    }

    public func directoryStructure(for url: URL) -> [String] {
        return []  // No subdirectories
    }
}
```

### PNG Compression Provider (Default)
```swift
public class PNGCompressionProvider: ImageCompressionProvider {
    public func compress(_ image: UIImage) -> Data? {
        return image.pngData()
    }

    public func decompress(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }

    public var fileExtension: String { "png" }
}
```

---

## 4. Custom Implementations Examples

### A. Hierarchical Storage (By Domain)
```swift
public class DomainHierarchicalPathProvider: StoragePathProvider {
    public func path(for url: URL, identifier: String) -> String {
        let domain = url.host ?? "unknown"
        let ext = url.pathExtension.isEmpty ? "png" : url.pathExtension
        return "\(domain)/\(identifier).\(ext)"
    }

    public func directoryStructure(for url: URL) -> [String] {
        return [url.host ?? "unknown"]
    }
}
```

### B. JPEG Compression (Save Space)
```swift
public class JPEGCompressionProvider: ImageCompressionProvider {
    public let quality: CGFloat

    public init(quality: CGFloat = 0.8) {
        self.quality = quality
    }

    public func compress(_ image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }

    public func decompress(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }

    public var fileExtension: String { "jpg" }
}
```

### C. Size-Based Conditional Compression
```swift
public class AdaptiveCompressionProvider: ImageCompressionProvider {
    private let sizeThresholdMB: Double
    private let pngProvider = PNGCompressionProvider()
    private let jpegProvider: JPEGCompressionProvider

    public init(sizeThresholdMB: Double = 1.0, jpegQuality: CGFloat = 0.8) {
        self.sizeThresholdMB = sizeThresholdMB
        self.jpegProvider = JPEGCompressionProvider(quality: jpegQuality)
    }

    public func compress(_ image: UIImage) -> Data? {
        // Try PNG first
        guard let pngData = pngProvider.compress(image) else { return nil }

        let sizeInMB = Double(pngData.count) / (1024 * 1024)

        // If too large, use JPEG
        if sizeInMB > sizeThresholdMB {
            return jpegProvider.compress(image)
        }

        return pngData
    }

    public func decompress(_ data: Data) -> UIImage? {
        return UIImage(data: data)  // UIKit handles both PNG/JPEG
    }

    public var fileExtension: String { "auto" }
}
```

### D. Image Resize Processor
```swift
public class ResizeImageProcessor: ImageProcessor {
    public let maxDimension: CGFloat

    public init(maxDimension: CGFloat = 1024) {
        self.maxDimension = maxDimension
    }

    public func process(_ image: UIImage, for url: URL) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else {
            return image  // Already small enough
        }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? image
    }

    public func shouldProcess(for url: URL) -> Bool {
        return true  // Always resize
    }
}
```

### E. LFU Cache Eviction Policy
```swift
public class LFUCacheEvictionPolicy: CacheEvictionPolicy {
    private var accessCounts: [String: Int] = [:]
    private let lock = NSLock()

    public func shouldEvict(resource: ResourceModel, currentCacheSize: Int, limit: Int) -> Bool {
        return currentCacheSize > limit
    }

    public func scoreForEviction(resource: ResourceModel) -> Double {
        lock.lock()
        defer { lock.unlock() }

        let count = accessCounts[resource.identifier] ?? 0
        return Double(count)  // Lower = evict first
    }

    public func recordAccess(for identifier: String) {
        lock.lock()
        defer { lock.unlock() }

        accessCounts[identifier, default: 0] += 1
    }
}
```

---

## 5. Configuration Integration

### Updated Configuration
```swift
public struct ImageDownloaderConfiguration {
    // Existing properties...

    // NEW: Customization providers
    public var identifierProvider: ResourceIdentifierProvider
    public var pathProvider: StoragePathProvider
    public var compressionProvider: ImageCompressionProvider
    public var metadataProvider: ResourceMetadataProvider?
    public var evictionPolicy: CacheEvictionPolicy
    public var imageProcessor: ImageProcessor?

    public init(
        maxConcurrentDownloads: Int = 4,
        // ... existing parameters ...

        // NEW: Custom providers with defaults
        identifierProvider: ResourceIdentifierProvider = MD5IdentifierProvider(),
        pathProvider: StoragePathProvider = FlatStoragePathProvider(),
        compressionProvider: ImageCompressionProvider = PNGCompressionProvider(),
        metadataProvider: ResourceMetadataProvider? = nil,
        evictionPolicy: CacheEvictionPolicy = LRUCacheEvictionPolicy(),
        imageProcessor: ImageProcessor? = nil
    ) {
        // ...
        self.identifierProvider = identifierProvider
        self.pathProvider = pathProvider
        self.compressionProvider = compressionProvider
        self.metadataProvider = metadataProvider
        self.evictionPolicy = evictionPolicy
        self.imageProcessor = imageProcessor
    }
}
```

---

## 6. Usage Examples

### Basic (Use Defaults)
```swift
let config = ImageDownloaderConfiguration()
ImageDownloaderManager.shared.configure(config)
```

### Custom Compression (JPEG to save space)
```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.85)
)
ImageDownloaderManager.shared.configure(config)
```

### Hierarchical Storage
```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DomainHierarchicalPathProvider(),
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)
ImageDownloaderManager.shared.configure(config)
```

### Full Customization
```swift
let config = ImageDownloaderConfiguration(
    identifierProvider: SHA256IdentifierProvider(),
    pathProvider: DateHierarchicalPathProvider(),
    compressionProvider: AdaptiveCompressionProvider(sizeThresholdMB: 2.0),
    metadataProvider: JSONMetadataProvider(),
    evictionPolicy: LFUCacheEvictionPolicy(),
    imageProcessor: ResizeImageProcessor(maxDimension: 2048)
)
ImageDownloaderManager.shared.configure(config)
```

---

## 7. Benefits

### For Library Users:
✅ **Flexibility** - Customize only what you need
✅ **Default Behavior** - Works out of the box without customization
✅ **Type Safety** - Protocol-based design with compile-time checks
✅ **Performance** - Optimize for your specific use case
✅ **Testability** - Easy to mock providers for testing

### For Library Maintainers:
✅ **Open/Closed Principle** - Open for extension, closed for modification
✅ **Single Responsibility** - Each provider has one job
✅ **Dependency Injection** - Easy to test and swap implementations
✅ **Backward Compatible** - Existing code works without changes

---

## 8. Migration Path

### Phase 1 (Current State)
- Fixed MD5 identifier
- Flat storage structure
- PNG compression only

### Phase 2 (This Upgrade) ✅
- Protocol-based architecture
- Default implementations (same behavior as Phase 1)
- Custom providers supported

### Phase 3 (Future)
- Built-in provider library (JPEG, WebP, HEIC, etc.)
- Advanced processors (filters, watermarks, etc.)
- Metadata indexing and search
- Multi-tier storage (fast SSD + slow HDD)

---

## 9. Objective-C Compatibility

### Challenge:
Protocols with associated types and generics don't bridge to Objective-C

### Solution:
Create Objective-C-compatible wrapper classes

```objc
// Objective-C
@interface IDCompressionProvider : NSObject
- (NSData * _Nullable)compressImage:(UIImage *)image;
- (UIImage * _Nullable)decompressData:(NSData *)data;
- (NSString *)fileExtension;
@end

@interface IDJPEGCompressionProvider : IDCompressionProvider
- (instancetype)initWithQuality:(CGFloat)quality;
@end
```

Swift protocols remain the primary interface, with Objective-C wrappers for compatibility.

---

## 10. Recommended Customizations

| Customization | When to Use | Benefit |
|---------------|-------------|---------|
| **JPEG Compression** | Photos, large images | Save 50-80% disk space |
| **Hierarchical Storage** | 1000+ images | Better file system performance |
| **Image Resize** | Display images | Reduce memory usage |
| **Adaptive Compression** | Mixed content | Balance quality & space |
| **Metadata Provider** | Analytics, debugging | Track usage patterns |
| **LFU Eviction** | Predictable usage | Keep frequently used images |

---

**Next Steps:** Implement the protocol-based system with default providers.
