# SwiftUI Demo - ImageDownloader

Comprehensive SwiftUI demo showcasing all ImageDownloader features.

## 📱 Demos Included

### 1. Storage Only Demo
**File:** `StorageOnlyDemoView.swift`

Demonstrates loading images from disk storage only, without network requests.

**Features:**
- Load images from disk storage
- Display storage statistics
- File count and size monitoring
- Clear storage functionality

**Use Cases:**
- Offline-first applications
- Viewing previously downloaded content
- Storage management

---

### 2. Storage Control Demo
**File:** `StorageControlDemoView.swift`

Advanced storage management with custom configurations.

**Features:**
- **Compression Algorithms:**
  - PNG (Lossless)
  - JPEG (with quality slider 10-100%)
  - Adaptive (automatic based on file size)

- **Folder Structures:**
  - Flat (all files in root directory)
  - Domain Hierarchical (organized by website: `example.com/abc123.png`)
  - Date Hierarchical (organized by date: `2025/10/07/abc123.png`)

- **File Explorer:**
  - Browse all stored files
  - View file sizes and modification dates
  - Real-time statistics

**Use Cases:**
- Optimizing disk space usage
- Organizing large image collections
- Custom storage strategies

---

### 3. Network Custom Demo
**File:** `NetworkCustomDemoView.swift`

Demonstrates custom network configurations for image loading.

**Features:**
- **Network Settings:**
  - Max concurrent downloads (1-20)
  - Timeout configuration (5-120 seconds)
  - Allow/disallow cellular data
  - Background task support

- **Retry Policy:**
  - Max retries (0-10)
  - Base delay (0.1-5.0 seconds)
  - Exponential backoff
  - Retry logging for debugging

- **Custom Headers:**
  - User-Agent customization
  - API key authentication
  - Custom header inspection

- **Testing:**
  - Custom URL input
  - Quick URL presets
  - Real-time progress tracking
  - Load time statistics
  - Source tracking (cache/storage/network)

**Use Cases:**
- API authentication
- Rate limiting
- Network optimization
- Custom CDN configurations

---

### 4. Full Featured Demo
**File:** `SwiftUIDemoApp.swift`

Complete example showing normal usage with all features enabled.

**Features:**
- Image grid with lazy loading
- Real-time statistics (cache, storage, active downloads)
- Automatic cell reuse handling
- Memory management
- Quick actions (clear cache, storage, all)

**Use Cases:**
- Social media feeds
- Photo galleries
- E-commerce apps

---

## 🚀 Getting Started

### Run the Demo

1. Open the project in Xcode
2. Select `SwiftUIDemoApp` as the target
3. Run on simulator or device (iOS 15+)

### Integration Examples

#### Basic Usage
```swift
import ImageDownloader

AsyncImageView(url: imageURL)
    .frame(width: 200, height: 200)
```

#### With Configuration
```swift
AsyncImageView(
    url: imageURL,
    config: FastConfig.shared,
    placeholder: Image("loading"),
    errorImage: Image("error")
)
.frame(width: 200, height: 200)
```

#### Storage Only
```swift
let storageAgent = ImageDownloaderManager.shared.storageAgent

if let image = await storageAgent.image(for: url) {
    imageView.image = image
}
```

#### Custom Network
```swift
var networkConfig = DefaultNetworkConfig()
networkConfig.maxConcurrentDownloads = 10
networkConfig.timeout = 60
networkConfig.customHeaders = ["X-API-Key": "your-key"]

let config = DefaultConfig(networkConfig: networkConfig)
let manager = ImageDownloaderManager.instance(for: config)
```

---

## 📊 Features Demonstrated

### ✅ SwiftUI Integration
- Native SwiftUI components
- Automatic lifecycle management
- State management with `@StateObject`
- Modern async/await patterns

### ✅ Storage Management
- Multiple compression formats
- Custom folder structures
- File inspection
- Size optimization

### ✅ Network Customization
- Concurrent download control
- Timeout configuration
- Custom headers
- Retry policies
- Progress tracking

### ✅ Performance Optimization
- Lazy loading
- Cell reuse handling
- Memory management
- Background task support

---

## 🎨 UI Components

### AsyncImageView
Pre-built SwiftUI component with automatic cancellation.

```swift
AsyncImageView(
    url: url,
    config: config,
    placeholder: Image(systemName: "photo"),
    errorImage: Image(systemName: "exclamationmark.triangle"),
    priority: .high
)
```

### StorageImageView
Load from storage only (no network).

```swift
StorageImageView(url: url)
    .frame(width: 100, height: 100)
```

---

## 💡 Best Practices Shown

1. **Always handle cell reuse** - Automatic in SwiftUI `.task(id:)`
2. **Use appropriate priority** - `.high` for visible, `.low` for thumbnails
3. **Configure per use case** - FastConfig, OfflineFirstConfig, LowMemoryConfig
4. **Monitor performance** - Real-time stats and logging
5. **Optimize storage** - Choose compression based on needs

---

## 🔧 Configuration Examples

### Fast Loading (Social Feed)
```swift
let config = FastConfig.shared
// - 8 concurrent downloads
// - Aggressive retry
// - Large cache
```

### Offline First (News App)
```swift
let config = OfflineFirstConfig.shared
// - WiFi only
// - Huge cache
// - Conservative retry
```

### Low Memory (Widgets)
```swift
let config = LowMemoryConfig.shared
// - Small cache
// - Moderate concurrency
```

---

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+

---

## 🎯 Learning Path

1. **Start with Full Featured Demo** - See everything working together
2. **Explore Storage Only** - Understand disk persistence
3. **Experiment with Storage Control** - Try different configurations
4. **Test Network Custom** - Fine-tune for your use case

---

## 📝 Code Quality

All demos demonstrate:
- ✅ Clean architecture
- ✅ MVVM pattern
- ✅ SwiftUI best practices
- ✅ Memory management
- ✅ Error handling
- ✅ Objective-C compatibility (where applicable)

---

## 🔗 Related Documentation

- [Main README](../../README.md)
- [Examples Guide](../../markdown/EXAMPLES.md)
- [Architecture](../../markdown/ARCHITECTURE.md)
- [Public API](../../markdown/PUBLIC_API.md)

---

## 🙏 Questions?

File an issue at [GitHub Issues](https://github.com/ductranprof99/Image-Downloader/issues)
