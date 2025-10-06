# Async/Await Support

Use modern Swift concurrency with async/await APIs.

## Overview

ImageDownloader is built with Swift concurrency, offering clean async/await APIs alongside traditional completion handlers. All async methods are available on iOS 13.0+ and macOS 10.15+.

## Basic Usage

### Simple Image Request

```swift
import ImageDownloader

func loadImage() async {
    do {
        let result = try await ImageDownloaderManager.shared.requestImage(at: imageURL)
        imageView.image = result.image

        // Check source
        if result.fromCache {
            print("✓ Loaded from memory cache")
        } else if result.fromStorage {
            print("✓ Loaded from disk storage")
        } else {
            print("✓ Downloaded from network")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

### With Progress Tracking

```swift
func loadImageWithProgress() async {
    do {
        let result = try await ImageDownloaderManager.shared.requestImage(
            at: imageURL,
            priority: .high,
            progress: { progress in
                // Called on main queue
                self.progressView.progress = Float(progress)
                print("Progress: \(Int(progress * 100))%")
            }
        )

        imageView.image = result.image
    } catch {
        handleError(error)
    }
}
```

## Error Handling

### Typed Errors

All async methods throw ``ImageDownloaderError`` for precise error handling:

```swift
do {
    let result = try await manager.requestImage(at: url)
    imageView.image = result.image
} catch let error as ImageDownloaderError {
    switch error {
    case .invalidURL:
        showError("Invalid image URL")

    case .networkError(let underlyingError):
        showError("Network failed: \(underlyingError.localizedDescription)")

    case .decodingFailed:
        showError("Could not decode image")

    case .cancelled:
        print("Download cancelled")

    case .timeout:
        showError("Request timed out")

    case .notFound:
        showError("Image not found")

    case .unknown(let underlyingError):
        showError("Unknown error: \(underlyingError.localizedDescription)")
    }
}
```

## Task Management

### Cancellation

Use Swift's `Task` for cancellable downloads:

```swift
class ImageViewController: UIViewController {
    private var downloadTask: Task<Void, Never>?

    func startDownload() {
        downloadTask = Task {
            do {
                let result = try await ImageDownloaderManager.shared.requestImage(at: url)
                imageView.image = result.image
            } catch is CancellationError {
                print("Download cancelled")
            } catch {
                handleError(error)
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelDownload()  // Auto-cancel on dismiss
    }
}
```

### Multiple Concurrent Downloads

Download multiple images in parallel:

```swift
func loadGallery(urls: [URL]) async {
    await withTaskGroup(of: ImageResult?.self) { group in
        for url in urls {
            group.addTask {
                try? await ImageDownloaderManager.shared.requestImage(at: url)
            }
        }

        var images: [UIImage] = []
        for await result in group {
            if let result = result {
                images.append(result.image)
            }
        }

        updateGallery(with: images)
    }
}
```

## Force Reload

Bypass cache and storage to force network download:

```swift
func refreshImage() async {
    do {
        let result = try await ImageDownloaderManager.shared.forceReloadImage(
            at: imageURL,
            priority: .high
        )
        imageView.image = result.image
    } catch {
        handleError(error)
    }
}
```

## Priority-Based Loading

Use priority to control download order:

```swift
// High priority (loaded first)
Task {
    let heroImage = try await manager.requestImage(
        at: heroURL,
        priority: .high
    )
    heroImageView.image = heroImage.image
}

// Low priority (loaded later)
Task {
    let thumbnail = try await manager.requestImage(
        at: thumbnailURL,
        priority: .low
    )
    thumbnailView.image = thumbnail.image
}
```

## Integration with SwiftUI

Use async/await directly in SwiftUI views:

```swift
import SwiftUI
import ImageDownloader

struct ContentView: View {
    @State private var image: UIImage?
    let imageURL: URL

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                let result = try await ImageDownloaderManager.shared.requestImage(at: imageURL)
                image = result.image
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

## Comparison: Async/Await vs Completion Handlers

### Async/Await (Recommended)

```swift
// ✅ Clean, readable, easy to follow
do {
    let result = try await manager.requestImage(at: url1)
    imageView1.image = result.image

    let result2 = try await manager.requestImage(at: url2)
    imageView2.image = result2.image

    let result3 = try await manager.requestImage(at: url3)
    imageView3.image = result3.image
} catch {
    handleError(error)
}
```

### Completion Handlers (Legacy)

```swift
// ⚠️ Callback pyramid, harder to read
manager.requestImage(at: url1) { image1, error1, _, _ in
    if let image1 = image1 {
        self.imageView1.image = image1

        self.manager.requestImage(at: url2) { image2, error2, _, _ in
            if let image2 = image2 {
                self.imageView2.image = image2

                self.manager.requestImage(at: url3) { image3, error3, _, _ in
                    if let image3 = image3 {
                        self.imageView3.image = image3
                    }
                }
            }
        }
    }
}
```

## Best Practices

1. **Use Task for Cancellation**
   ```swift
   let task = Task { try await downloadImage() }
   // Cancel when needed: task.cancel()
   ```

2. **Handle Errors Properly**
   ```swift
   catch let error as ImageDownloaderError { /* Handle */ }
   ```

3. **Leverage Structured Concurrency**
   ```swift
   async let image1 = manager.requestImage(at: url1)
   async let image2 = manager.requestImage(at: url2)
   let results = try await [image1, image2]
   ```

4. **Cancel on Dismiss**
   ```swift
   override func viewWillDisappear(_ animated: Bool) {
       downloadTask?.cancel()
   }
   ```

## Topics

### Core Types

- ``ImageDownloaderManager``
- ``ImageResult``
- ``ImageDownloaderError``

### Related

- <doc:GettingStarted>
- <doc:Configuration>
