# ImageDownloader - Example Projects

Complete example projects demonstrating ImageDownloader usage across different platforms and languages.

---

## Available Examples

### 1. UIKitDemo ⭐

**Full-featured UIKit app with progress tracking**

Features:
- Image feed with collection view
- Progress tracking and statistics
- Cache management UI
- Download statistics
- Error handling
- Swipe actions for cell management

**Location:** `Examples/UIKitDemo/`

**To Run:**
```bash
cd Examples/UIKitDemo/TestLibUIKit
open TestLibUIKit.xcodeproj
```

---

### 2. SwiftUIDemo 🆕⭐

**Comprehensive SwiftUI demos showcasing all features**

Features:
- **Storage Only Demo** - Load images from disk only (no network)
- **Storage Control Demo** - File explorer, compression algorithms, folder structures
- **Network Custom Demo** - Custom headers, retry policies, URL testing
- **Full Featured Demo** - Complete working example with statistics

**Location:** `Examples/SwiftUIDemo/`

**Key Features:**
- ✅ Multiple compression formats (PNG, JPEG, Adaptive)
- ✅ Custom folder structures (Flat, Domain, Date hierarchical)
- ✅ File browser with size/date info
- ✅ Network configuration (concurrent downloads, timeout, retry)
- ✅ Real-time statistics and monitoring
- ✅ Easy to use, well-documented

**To Run:**
```swift
// The files are ready to integrate into any SwiftUI project
// See Examples/SwiftUIDemo/README.md for details
```

---

### 3. ObjectiveCDemo 🆕

**Complete Objective-C integration examples**

Features:
- ✅ Full Objective-C compatibility demonstration
- ✅ UIImageView category usage
- ✅ Manager API examples
- ✅ Custom configuration in Objective-C
- ✅ JPEG/PNG compression providers
- ✅ Domain/Date hierarchical storage
- ✅ Cache management
- ✅ Statistics and monitoring

**Location:** `Examples/ObjectiveCDemo/`

**To Run:**
```objc
// Include in any Objective-C project
// See Examples/ObjectiveCDemo/README.md for integration guide
```

---

## Features Comparison

| Feature | UIKitDemo | SwiftUIDemo | ObjectiveCDemo |
|---------|-----------|-------------|----------------|
| Progress bars | ✅ | ✅ | ✅ |
| Feed/List view | ✅ | ✅ | ✅ |
| Storage-only loading | ❌ | ✅ | ✅ |
| File browser | ❌ | ✅ | ❌ |
| Compression control | ❌ | ✅ | ✅ |
| Folder structure config | ❌ | ✅ | ✅ |
| Network customization | ❌ | ✅ | ✅ |
| Cache management | ✅ | ✅ | ✅ |
| Config switching | ✅ | ✅ | ✅ |
| Objective-C compatible | ❌ | ❌ | ✅ |

---

## Test Image URLs

Both projects use randomly generated test URLs from placeholder image services:

- **Picsum Photos**: https://picsum.photos/
- **Placeholder.com**: https://via.placeholder.com/
- **DummyImage**: https://dummyimage.com/

1000 unique URLs are generated for testing various scenarios.

---

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+
- ImageDownloader library (via SPM)

---

## Installation

Both projects use Swift Package Manager to include ImageDownloader:

1. Open the project in Xcode
2. The package dependency is already configured
3. Build and run

**Package URL:** https://github.com/ductranprof99/Image-Downloader.git

---

## Usage Patterns Demonstrated

### UIKitDemo

```swift
// Progress tracking
imageView.setImage(
    with: url,
    config: FastConfig.shared,
    placeholder: placeholderImage,
    onProgress: { progress in
        progressView.progress = Float(progress)
    },
    onCompletion: { image, error, fromCache, fromStorage in
        // Handle completion
    }
)
```

### SwiftUIDemo

```swift
// Feed with ImageLoader
struct FeedItemView: View {
    @StateObject private var loader = ImageLoader()

    var body: some View {
        if let image = loader.image {
            Image(uiImage: image)
        } else {
            ProgressView(value: loader.progress)
        }
    }
}
```

---

## Project Structure

### UIKitDemo Structure

```
UIKitDemo/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── ViewControllers/
│   ├── FeedViewController.swift
│   ├── DetailViewController.swift
│   └── SettingsViewController.swift
├── Views/
│   ├── ImageCell.swift
│   └── ProgressCell.swift
├── Models/
│   └── ImageItem.swift
└── Resources/
    ├── Assets.xcassets
    └── LaunchScreen.storyboard
```

### SwiftUIDemo Structure

```
SwiftUIDemo/
├── App/
│   └── SwiftUIDemoApp.swift
├── Views/
│   ├── FeedView.swift
│   ├── DownloadsView.swift
│   ├── DebugView.swift
│   └── SettingsView.swift
├── Components/
│   ├── FeedItemView.swift
│   ├── ProgressIndicator.swift
│   └── FolderBrowser.swift
├── Models/
│   ├── ImageItem.swift
│   └── DownloadStats.swift
├── ViewModels/
│   ├── FeedViewModel.swift
│   └── DebugViewModel.swift
└── Resources/
    └── Assets.xcassets
```

---

## Learning Resources

- **[Complete Documentation](../DOCUMENTATION.md)** - Full library documentation
- **[Configuration Guide](../markdown/CONFIGURATION.md)** - Configuration options
- **[Architecture Guide](../markdown/ARCHITECTURE.md)** - System architecture
- **[Examples Guide](../markdown/EXAMPLES.md)** - Code examples

---

## Support

- **Issues**: [GitHub Issues](https://github.com/ductranprof99/Image-Downloader/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ductranprof99/Image-Downloader/discussions)
- **Documentation**: [https://ductranprof99.github.io/Image-Downloader/](https://ductranprof99.github.io/Image-Downloader/)
