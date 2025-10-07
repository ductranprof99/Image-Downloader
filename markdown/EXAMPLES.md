# ImageDownloader - Examples

Practical code examples for common use cases.

---

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Placeholder & Error Images](#placeholder--error-images)
3. [Image Transformations](#image-transformations)
4. [Cancellation Patterns](#cancellation-patterns)
5. [Async/Await Usage](#asyncawait-usage)
6. [Custom Configuration](#custom-configuration)
7. [Complete Examples](#complete-examples)

---

## Basic Usage

### UIKit - Simple

```swift
import ImageDownloader

// Simplest form
imageView.setImage(with: url)

// With placeholder
imageView.setImage(
    with: url,
    placeholder: UIImage(named: "placeholder")
)
```

### SwiftUI - Simple

```swift
import ImageDownloader

AsyncImageView(url: url)
    .frame(width: 200, height: 200)
```

---

## Placeholder & Error Images

### UIKit

```swift
// Separate images for loading vs error
imageView.setImage(
    with: url,
    placeholder: UIImage(named: "loading"),    // While loading
    errorImage: UIImage(named: "broken_image") // On error
)
```

### SwiftUI

```swift
AsyncImageView(
    url: url,
    placeholder: Image("loading"),
    errorImage: Image("broken_image")
)
.frame(width: 200, height: 200)
```

---

## Image Transformations

### Circular Avatar

```swift
// Perfect for profile pictures
imageView.setImage(
    with: user.avatarURL,
    placeholder: UIImage(named: "default_avatar"),
    errorImage: UIImage(named: "broken_avatar"),
    transformation: CircleTransformation(diameter: 80)
)
```

### Rounded Corners

```swift
imageView.setImage(
    with: url,
    placeholder: placeholder,
    transformation: RoundedCornersTransformation(
        cornerRadius: 16,
        targetSize: CGSize(width: 200, height: 200)
    )
)
```

### Resize with Aspect

```swift
// Aspect fill (crop to fit)
let transform = ResizeTransformation(
    targetSize: CGSize(width: 300, height: 200),
    contentMode: .scaleAspectFill
)

imageView.setImage(
    with: url,
    placeholder: placeholder,
    transformation: transform
)

// Aspect fit (letterbox)
let transform = ResizeTransformation(
    targetSize: CGSize(width: 300, height: 200),
    contentMode: .scaleAspectFit
)
```

### Multiple Transformations

```swift
// Chain multiple transformations
let composite = CompositeTransformation(transformations: [
    ResizeTransformation(targetSize: CGSize(width: 200, height: 200)),
    CircleTransformation(diameter: 200)
])

imageView.setImage(with: url, transformation: composite)
```

---

## Cancellation Patterns

### UIKit - Table View Cell

```swift
class ImageCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel previous loading
        avatarImageView.cancelImageLoading()
    }

    func configure(with url: URL) {
        avatarImageView.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"),
            errorImage: UIImage(named: "error")
        )
    }
}
```

### UIKit - Collection View Cell

```swift
class PhotoCell: UICollectionViewCell {
    let imageView = UIImageView()

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelImageLoading()
        imageView.image = nil
    }

    func configure(with url: URL) {
        imageView.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"),
            transformation: ResizeTransformation(
                targetSize: CGSize(width: 150, height: 150),
                contentMode: .scaleAspectFill
            )
        )
    }
}
```

### SwiftUI - Automatic

```swift
// Cancels automatically when view disappears
List(images, id: \.url) { item in
    AsyncImageView(url: item.url)
        .frame(width: 60, height: 60)
        .clipShape(Circle())
}
```

### SwiftUI - Manual Control

```swift
struct ImageView: View {
    @StateObject private var loader = ImageLoader()
    let url: URL

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loader.load(from: url)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
```

---

## Async/Await Usage

### Basic

```swift
Task {
    do {
        let result = try await ImageDownloaderManager.shared
            .requestImageAsync(at: url)

        await MainActor.run {
            imageView.image = result.image
            print("From cache: \(result.fromCache)")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

### With Progress

```swift
Task {
    for try await event in manager.requestImageWithProgress(at: url) {
        switch event {
        case .progress(let value):
            await MainActor.run {
                progressView.progress = Float(value)
            }

        case .completed(let result):
            await MainActor.run {
                imageView.image = result.image
                progressView.isHidden = true
            }
        }
    }
}
```

### With Cancellation

```swift
class ImageViewController: UIViewController {
    private var loadTask: Task<Void, Never>?

    func loadImage(url: URL) {
        // Cancel previous task
        loadTask?.cancel()

        loadTask = Task {
            do {
                let result = try await ImageDownloaderManager.shared
                    .requestImageAsync(at: url)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    imageView.image = result.image
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    deinit {
        loadTask?.cancel()
    }
}
```

---

## Custom Configuration

### Enable Retry Logging (Debug)

```swift
// Enable logging to see retry attempts
let config = ConfigBuilder()
    .retryPolicy(RetryPolicy(
        maxRetries: 3,
        baseDelay: 1.0,
        backoffMultiplier: 2.0
    ))
    .enableDebugLogging(true)  // Shows retry logs
    .build()

let manager = ImageDownloaderManager.instance(for: config)
```

Output:
```
[ImageDownloader] 🔄 Retry 1/3 for image.jpg after 1.0s - Error: timeout
[ImageDownloader] 🔄 Retry 2/3 for image.jpg after 2.0s - Error: timeout
[ImageDownloader] ❌ Max retries (3) reached for image.jpg
```

### Custom Network Config

```swift
// Option 1: Using ConfigBuilder (Recommended)
let config = ConfigBuilder()
    .maxConcurrentDownloads(10)
    .timeout(30)
    .retryPolicy(.aggressive)  // Use RetryPolicy static presets
    .customHeaders(["User-Agent": "MyApp/1.0"])
    .authenticationHandler { request in
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    }
    .allowsCellularAccess(true)
    .enableDebugLogging(true)
    .build()

let manager = ImageDownloaderManager.instance(for: config)
imageView.setImage(with: url, config: config)

// Option 2: Direct IDConfiguration (ObjC compatible)
let networkConfig = IDNetworkConfig(
    maxConcurrentDownloads: 10,
    timeout: 30,
    allowsCellularAccess: true,
    retryPolicy: IDRetryPolicy.aggressivePolicy(),
    customHeaders: ["User-Agent": "MyApp/1.0"],
    authenticationHandler: { request in
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    }
)

let config = IDConfiguration(
    network: networkConfig,
    cache: IDCacheConfig(highPriorityLimit: 100, lowPriorityLimit: 200),
    storage: IDStorageConfig(shouldSaveToStorage: true),
    enableDebugLogging: true
)

let manager = ImageDownloaderManager.instance(for: config)
```

### Use Preset Configs

```swift
// High performance - high concurrency, aggressive retry
imageView.setImage(with: url, config: IDConfiguration.highPerformance)

// Offline-first - prefers cache/storage, conservative network
imageView.setImage(with: url, config: IDConfiguration.offlineFirst)

// Low memory - small cache limits
imageView.setImage(with: url, config: IDConfiguration.lowMemory)

// Default - balanced settings
imageView.setImage(with: url, config: IDConfiguration.default)

// Custom preset using builder
let config = ConfigBuilder.highPerformance()
    .maxConcurrentDownloads(12)  // Override specific settings
    .build()

imageView.setImage(with: url, config: config)
```

---

## Complete Examples

### Social Media Feed

```swift
class FeedViewController: UITableViewController {
    var posts: [Post] = []

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
        let post = posts[indexPath.row]

        cell.configure(with: post)

        return cell
    }
}

class FeedCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.cancelImageLoading()
        photoImageView.cancelImageLoading()
        avatarImageView.image = nil
        photoImageView.image = nil
    }

    func configure(with post: Post) {
        usernameLabel.text = post.username

        // Avatar - circular, high priority
        avatarImageView.setImage(
            with: post.avatarURL,
            placeholder: UIImage(named: "default_avatar"),
            errorImage: UIImage(named: "broken_avatar"),
            priority: .high,
            transformation: CircleTransformation(diameter: 40)
        )

        // Photo - rectangular, normal priority
        photoImageView.setImage(
            with: post.photoURL,
            placeholder: UIImage(named: "photo_placeholder"),
            errorImage: UIImage(named: "photo_error"),
            priority: .low
        )
    }
}
```

### SwiftUI Image Grid

```swift
struct ImageGridView: View {
    let imageURLs: [URL]

    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(imageURLs, id: \.self) { url in
                    AsyncImageView(
                        url: url,
                        placeholder: Image(systemName: "photo"),
                        errorImage: Image(systemName: "photo.fill")
                    )
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
    }
}
```

### Progress Tracking

```swift
class ImageDetailViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!

    var imageURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.setImage(
            with: imageURL,
            placeholder: UIImage(named: "loading"),
            priority: .high,
            onProgress: { [weak self] progress in
                self?.progressView.progress = Float(progress)
            },
            onCompletion: { [weak self] image, error, fromCache, fromStorage in
                self?.progressView.isHidden = true

                if let error = error {
                    self?.showError(error)
                }
            }
        )
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Observer Pattern

```swift
class ImageLoadingObserver: ImageDownloaderObserver {
    var requiresMainThread: Bool { true }

    func imageDidLoad(for url: URL, fromCache: Bool, fromStorage: Bool) {
        let source = fromCache ? "cache" : (fromStorage ? "storage" : "network")
        print("✅ Loaded from \(source): \(url.lastPathComponent)")
    }

    func imageDidFail(for url: URL, error: Error) {
        print("❌ Failed: \(url.lastPathComponent) - \(error.localizedDescription)")
    }

    func imageDownloadProgress(for url: URL, progress: CGFloat) {
        print("📥 Progress: \(url.lastPathComponent) - \(Int(progress * 100))%")
    }

    func imageWillStartDownloading(for url: URL) {
        print("🚀 Starting: \(url.lastPathComponent)")
    }
}

// Register observer
let observer = ImageLoadingObserver()
ImageDownloaderManager.shared.addObserver(observer)
```

---

## Error Handling

### Completion Handler

```swift
imageView.setImage(
    with: url,
    placeholder: placeholder,
    onCompletion: { image, error, fromCache, fromStorage in
        if let error = error {
            switch error {
            case ImageDownloaderError.networkError:
                print("Network error")
            case ImageDownloaderError.timeout:
                print("Request timed out")
            case ImageDownloaderError.cancelled:
                print("Request cancelled")
            case ImageDownloaderError.notFound:
                print("Image not found (404)")
            case ImageDownloaderError.decodingFailed:
                print("Invalid image data")
            default:
                print("Unknown error: \(error)")
            }
        }
    }
)
```

### Async/Await

```swift
Task {
    do {
        let result = try await manager.requestImageAsync(at: url)
        imageView.image = result.image
    } catch ImageDownloaderError.timeout {
        print("Timeout - retry?")
    } catch ImageDownloaderError.networkError(let underlyingError) {
        print("Network error: \(underlyingError)")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## Cache Management

```swift
// Clear low-priority cache
ImageDownloaderManager.shared.clearLowPriorityCache()

// Clear all cache
ImageDownloaderManager.shared.clearAllCache()

// Clear disk storage
ImageDownloaderManager.shared.clearStorage { success in
    print("Storage cleared: \(success)")
}

// Hard reset (cache + storage)
ImageDownloaderManager.shared.hardReset()

// Check stats
let manager = ImageDownloaderManager.shared
print("High priority cache: \(manager.cacheSizeHigh())")
print("Low priority cache: \(manager.cacheSizeLow())")
print("Storage size: \(manager.storageSizeBytes()) bytes")
print("Active downloads: \(manager.activeDownloadsCount())")
```

---

## Tips & Best Practices

### 1. Always Cancel in Cell Reuse

```swift
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.cancelImageLoading()  // Important!
}
```

### 2. Use Priority Wisely

```swift
// High priority - important, visible images
avatarImageView.setImage(with: url, priority: .high)

// Low priority - thumbnails, off-screen
thumbnailView.setImage(with: url, priority: .low)
```

### 3. Use Transformations for Performance

```swift
// Good: Transform once during download
imageView.setImage(
    with: url,
    transformation: ResizeTransformation(targetSize: size)
)

// Less efficient: Transform manually after download
manager.requestImage(at: url) { image, _, _, _ in
    let resized = image?.resized(to: size)
    imageView.image = resized
}
```

### 4. Enable Logging During Development

```swift
#if DEBUG
let config = ConfigBuilder()
    .retryPolicy(RetryPolicy(maxRetries: 3, baseDelay: 1.0))
    .enableDebugLogging(true)
    .build()
#else
let config = IDConfiguration.default
#endif

let manager = ImageDownloaderManager.instance(for: config)
```
