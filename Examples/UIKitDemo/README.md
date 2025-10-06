# UIKitDemo - ImageDownloader Example

UIKit example app demonstrating ImageDownloader with progress tracking.

## Features

- ✅ Image loading with progress bars
- ✅ Multiple image sizes (avatars, photos)
- ✅ Cache statistics
- ✅ Download speed tracking
- ✅ Error handling
- ✅ Configuration switching
- ✅ Pull-to-refresh
- ✅ Cell reuse handling

## Screenshots

- Feed with progress bars
- Detail view with large images
- Settings with cache management

## How to Run

1. Open `UIKitDemo.xcodeproj` in Xcode
2. Build and run (⌘R)
3. Scroll through the feed to see image loading

## Key Classes

### FeedViewController
Main view controller with UITableView displaying images with progress.

### ImageCell
Custom table view cell with:
- UIImageView
- UIProgressView
- UILabel for status

### SettingsViewController
Settings screen with:
- Config selection (Fast, OfflineFirst, LowMemory)
- Cache management (Clear cache buttons)
- Statistics (Cache size, downloads)

## Code Highlights

### Loading with Progress

```swift
cell.imageView.setImage(
    with: url,
    config: FastConfig.shared,
    placeholder: UIImage(named: "placeholder"),
    onProgress: { progress in
        cell.progressView.progress = Float(progress)
        cell.progressView.isHidden = (progress >= 1.0)
    },
    onCompletion: { image, error, fromCache, fromStorage in
        cell.progressView.isHidden = true

        if fromCache {
            cell.statusLabel.text = "✅ From cache"
        } else if fromStorage {
            cell.statusLabel.text = "💾 From storage"
        } else {
            cell.statusLabel.text = "🌐 Downloaded"
        }
    }
)
```

### Cell Reuse

```swift
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.cancelImageLoading()
    progressView.progress = 0
    progressView.isHidden = true
}
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+
