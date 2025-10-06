# Getting Started

Download and cache images with just a few lines of code.

## Overview

ImageDownloader provides both modern Swift async/await APIs and traditional completion handler APIs. Choose the style that fits your project best.

## Installation

### Swift Package Manager

Add ImageDownloader to your project via Xcode:

1. File → Add Packages
2. Enter repository URL: `https://github.com/ductranprof99/ImageDownloaderController.git`
3. Select version: 2.0.0 or later
4. Choose targets:
   - `ImageDownloader` - Core library (required)
   - `ImageDownloaderUI` - UIKit integration
   - `ImageDownloaderComponentKit` - ComponentKit integration

Or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ductranprof99/ImageDownloaderController.git", from: "2.0.0")
]
```

## Quick Start (Swift)

### Basic Usage with Async/Await

```swift
import ImageDownloader

// Simple async/await
Task {
    do {
        let result = try await ImageDownloaderManager.shared.requestImage(at: imageURL)
        imageView.image = result.image
        print("Loaded from: \(result.fromCache ? "cache" : "network")")
    } catch {
        print("Error: \(error)")
    }
}
```

### With UIKit Integration

```swift
import ImageDownloaderUI

let imageView = AsyncImageView()
imageView.placeholderImage = UIImage(named: "placeholder")
imageView.priority = .high

imageView.onProgress = { progress in
    print("Loading: \(Int(progress * 100))%")
}

imageView.loadImage(from: imageURL)
```

### Using UIImageView Extension

```swift
import ImageDownloaderUI

imageView.setImage(
    with: imageURL,
    placeholder: UIImage(named: "placeholder"),
    priority: .high
)
```

## Quick Start (Objective-C)

```objc
@import ImageDownloader;

[[ImageDownloaderManager shared] requestImageAt:imageURL
                                     completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
    if (image) {
        self.imageView.image = image;
    }
}];
```

## Next Steps

- <doc:Configuration> - Configure caching and storage behavior
- <doc:AsyncAwait> - Learn about async/await features
- <doc:Customization> - Customize compression and storage
