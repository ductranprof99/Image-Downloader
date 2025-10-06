# ImageDownloader - Example Projects

Complete example projects demonstrating ImageDownloader usage.

---

## Available Examples

### 1. UIKitDemo

**UIKit app with progress tracking**

Features:
- Image loading with progress bar
- Multiple image types (avatars, photos)
- Cache management UI
- Download statistics
- Error handling

**Location:** `Examples/UIKitDemo/`

**To Run:**
```bash
cd Examples/UIKitDemo
open UIKitDemo.xcodeproj
```

---

### 2. SwiftUIDemo

**SwiftUI app with feed, tabs, and debugging tools**

Features:
- Multi-tab interface (Feed, Downloads, Debug, Settings)
- Feed with multiple images (1000+ test URLs)
- Progress tracking in feed cells
- Downloaded images folder browser
- Debug view showing all download activity
- Network statistics
- Configuration switcher

**Location:** `Examples/SwiftUIDemo/`

**To Run:**
```bash
cd Examples/SwiftUIDemo
open SwiftUIDemo.xcodeproj
```

---

## Features Comparison

| Feature | UIKitDemo | SwiftUIDemo |
|---------|-----------|-------------|
| Progress bars | ✅ | ✅ |
| Feed/List view | ✅ | ✅ |
| Tab bar navigation | ❌ | ✅ |
| Folder browser | ❌ | ✅ |
| Debug view | ❌ | ✅ |
| 1000+ image URLs | ❌ | ✅ |
| Cache management | ✅ | ✅ |
| Config switching | ✅ | ✅ |

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
