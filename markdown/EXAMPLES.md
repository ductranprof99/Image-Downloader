# ImageDownloader - Usage Examples

Complete, ready-to-use examples for common use cases.

---

## Table of Contents

1. [Social Media App](#social-media-app)
2. [E-Commerce App](#e-commerce-app)
3. [Progress Tracking in UIKit](#progress-tracking-in-uikit)
4. [Progress Tracking in SwiftUI](#progress-tracking-in-swiftui)
5. [Authenticated API](#authenticated-api)
6. [UIImage Direct Loading](#uiimage-direct-loading)
7. [UIImageView Extension](#uiimageview-extension)
8. [Custom Configuration](#custom-configuration)

---

## Social Media App

A complete configuration setup for a social media app with different configs for avatars, feed photos, full photos, and stories.

```swift
import ImageDownloader

struct SocialMediaConfig {
    // Avatars: small, fast, high priority
    static let avatar = ConfigBuilder()
        .maxConcurrentDownloads(8)
        .cacheSize(high: 150, low: 300)
        .retryPolicy(.aggressive)
        .compressionProvider(JPEGCompressionProvider(quality: 0.7))
        .build()

    // Feed photos: balanced
    static let feed = ConfigBuilder()
        .maxConcurrentDownloads(6)
        .cacheSize(high: 100, low: 200)
        .compressionProvider(JPEGCompressionProvider(quality: 0.8))
        .build()

    // Full photos: offline-first
    static let fullPhoto = OfflineFirstConfig.shared

    // Stories: fast, low quality, don't save
    static let story = ConfigBuilder()
        .maxConcurrentDownloads(10)
        .enableStorage(false)
        .compressionProvider(JPEGCompressionProvider(quality: 0.6))
        .build()
}

// Usage in UITableViewCell
class FeedCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var photoImageView: UIImageView!

    func configure(with post: Post) {
        avatarImageView.setImage(
            with: post.user.avatarURL,
            config: SocialMediaConfig.avatar,
            placeholder: UIImage(named: "avatar_placeholder"),
            priority: .high
        )

        photoImageView.setImage(
            with: post.photoURL,
            config: SocialMediaConfig.feed,
            placeholder: UIImage(named: "photo_placeholder")
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.cancelImageLoading()
        photoImageView.cancelImageLoading()
    }
}
```

---

## E-Commerce App

Product image loading with different configs for thumbnails, main images, and zoom views.

```swift
import ImageDownloader

struct ECommerceConfig {
    static let productThumbnail = LowMemoryConfig.shared
    static let productImage = FastConfig.shared
    static let productZoom = OfflineFirstConfig.shared
}

class ProductViewController: UIViewController {
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!

    func loadProduct(_ product: Product) {
        // Thumbnail
        thumbnailView.setImage(
            with: product.thumbnailURL,
            config: ECommerceConfig.productThumbnail,
            placeholder: UIImage(named: "product_placeholder")
        )

        // Main image with async/await
        Task {
            do {
                let image = try await UIImage.load(
                    from: product.imageURL,
                    config: ECommerceConfig.productImage
                )
                imageView.image = image
            } catch {
                print("Failed to load product image: \(error)")
            }
        }
    }
}
```

---

## Progress Tracking in UIKit

Complete example showing progress bar updates during image download.

### UIImageView with Progress

```swift
import ImageDownloader

class FeedCell: UITableViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!

    func configure(with post: Post) {
        // Show progress UI
        progressView.isHidden = false
        progressView.progress = 0
        progressLabel.isHidden = false

        photoImageView.setImage(
            with: post.photoURL,
            config: FastConfig.shared,
            placeholder: UIImage(named: "placeholder"),
            onProgress: { [weak self] progress in
                // Update progress bar
                self?.progressView.progress = Float(progress)
                self?.progressLabel.text = "\(Int(progress * 100))%"
            },
            onCompletion: { [weak self] image, error, fromCache, fromStorage in
                // Hide progress when done
                self?.progressView.isHidden = true
                self?.progressLabel.isHidden = true

                // If from cache, it was instant - user didn't see progress
                if fromCache || fromStorage {
                    print("✅ Loaded instantly from cache/storage")
                } else {
                    print("✅ Downloaded from network")
                }

                if let error = error {
                    print("❌ Error: \(error)")
                }
            }
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.cancelImageLoading()
        progressView.progress = 0
        progressView.isHidden = true
        progressLabel.isHidden = true
    }
}
```

### UIImage.load() with Progress

```swift
import ImageDownloader

class PhotoViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!

    var imageURL: URL!

    func loadImage() {
        progressView.isHidden = false
        progressView.progress = 0

        UIImage.load(
            from: imageURL,
            config: FastConfig.shared,
            progress: { [weak self] progress in
                self?.progressView.progress = Float(progress)
            },
            completion: { [weak self] result in
                self?.progressView.isHidden = true

                switch result {
                case .success(let image):
                    self?.imageView.image = image
                case .failure(let error):
                    print("Failed to load image: \(error)")
                }
            }
        )
    }
}
```

---

## Progress Tracking in SwiftUI

Using `ImageLoader` ObservableObject for SwiftUI progress tracking.

```swift
import SwiftUI
import ImageDownloader

struct FeedView: View {
    let posts: [Post]

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(posts) { post in
                    FeedItemView(post: post)
                }
            }
        }
    }
}

struct FeedItemView: View {
    let post: Post
    @StateObject private var imageLoader = ImageLoader()

    var body: some View {
        VStack(alignment: .leading) {
            // Image with progress
            ZStack {
                if let image = imageLoader.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                ProgressView(value: imageLoader.progress, total: 1.0)
                                    .scaleEffect(1.5)
                                    .padding(.horizontal, 40)

                                if imageLoader.progress > 0 {
                                    Text("\(Int(imageLoader.progress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                }
            }

            Text(post.title)
                .font(.headline)
                .padding()
        }
        .onAppear {
            imageLoader.load(from: post.photoURL, config: FastConfig.shared)
        }
        .onDisappear {
            imageLoader.cancel()
        }
    }
}

// Simple photo viewer
struct PhotoView: View {
    let imageURL: URL
    @StateObject private var loader = ImageLoader()

    var body: some View {
        VStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if loader.isLoading {
                VStack(spacing: 16) {
                    ProgressView(value: loader.progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 200)

                    Text("Loading \(Int(loader.progress * 100))%")
                        .font(.caption)
                }
            } else if let error = loader.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            loader.load(from: imageURL)
        }
    }
}
```

---

## Authenticated API

Loading images from a private API with authentication tokens and custom headers.

```swift
import ImageDownloader

struct PrivateAPIConfig: ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol {
        var config = DefaultNetworkConfig()
        config.authenticationHandler = { request in
            // Add bearer token
            if let token = AuthManager.shared.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            // Add user agent
            request.setValue("MyApp/1.0", forHTTPHeaderField: "User-Agent")
        }

        config.customHeaders = [
            "X-Client-ID": "my-client-id",
            "X-API-Version": "v2"
        ]

        config.retryPolicy = .aggressive
        return config
    }

    var cacheConfig: CacheConfigProtocol {
        DefaultCacheConfig()
    }

    var storageConfig: StorageConfigProtocol {
        DefaultStorageConfig()
    }
}

// Usage
class PrivateImageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    func loadPrivateImage(url: URL) {
        Task {
            do {
                let config = PrivateAPIConfig()
                let image = try await UIImage.load(from: url, config: config)
                imageView.image = image
            } catch {
                print("Failed to load private image: \(error)")
            }
        }
    }
}
```

### Using ConfigBuilder for Auth

```swift
// Quick auth setup with ConfigBuilder
let authConfig = ConfigBuilder()
    .authenticationHandler { request in
        let token = KeychainManager.getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    .customHeaders([
        "User-Agent": "MyApp/1.0",
        "X-API-Key": "secret_key"
    ])
    .retryPolicy(.aggressive)
    .build()

// Load image
let image = try await UIImage.load(from: privateImageURL, config: authConfig)
```

---

## UIImage Direct Loading

Using `UIImage.load()` extension for direct image loading without UIImageView.

### Async/Await (Recommended)

```swift
import ImageDownloader

class ImageProcessor: NSObject {
    func processImage(from url: URL) async {
        do {
            // Simple load
            let image = try await UIImage.load(from: url)

            // With custom config
            let fastImage = try await UIImage.load(
                from: url,
                config: FastConfig.shared,
                priority: .high
            )

            // Process the image
            let processed = applyFilters(to: image)
            saveToLibrary(processed)
        } catch {
            print("Error loading image: \(error)")
        }
    }
}
```

### Completion Handler

```swift
import ImageDownloader

class ImageManager: NSObject {
    func loadImage(from url: URL) {
        // Simple load
        UIImage.load(from: url) { result in
            switch result {
            case .success(let image):
                print("Image loaded: \(image.size)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }

        // With progress and config
        UIImage.load(
            from: url,
            config: FastConfig.shared,
            priority: .high,
            progress: { progress in
                print("Loading: \(Int(progress * 100))%")
            },
            completion: { result in
                switch result {
                case .success(let image):
                    // Use image
                    self.cache[url] = image
                case .failure(let error):
                    print("Failed: \(error)")
                }
            }
        )
    }
}
```

### String URL Support

```swift
// Load from string URL
let urlString = "https://example.com/image.jpg"
let image = try await UIImage.load(from: urlString)
```

---

## UIImageView Extension

Convenient image loading directly into UIImageView with placeholders and progress.

### Basic Usage

```swift
import ImageDownloaderUI

class MyViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    func loadSimple() {
        // Simplest usage
        imageView.setImage(with: imageURL)

        // With placeholder
        imageView.setImage(
            with: imageURL,
            placeholder: UIImage(named: "placeholder")
        )

        // With priority
        imageView.setImage(
            with: imageURL,
            placeholder: placeholderImage,
            priority: .high
        )
    }
}
```

### Full Featured

```swift
import ImageDownloaderUI

class AdvancedViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!

    func loadAdvanced() {
        imageView.setImage(
            with: imageURL,
            config: FastConfig.shared,
            placeholder: UIImage(named: "placeholder"),
            priority: .high,
            onProgress: { [weak self] progress in
                self?.progressView.progress = Float(progress)
                self?.progressView.isHidden = (progress >= 1.0)
            },
            onCompletion: { [weak self] image, error, fromCache, fromStorage in
                self?.progressView.isHidden = true

                if fromCache {
                    print("✅ From memory cache")
                } else if fromStorage {
                    print("✅ From disk storage")
                } else {
                    print("✅ Downloaded from network")
                }

                if let error = error {
                    print("❌ Error: \(error)")
                    self?.imageView.image = UIImage(named: "error_placeholder")
                }
            }
        )
    }

    func cancelLoading() {
        imageView.cancelImageLoading()
    }
}
```

---

## Custom Configuration

Creating fully custom configurations for specific needs.

### Custom Config Protocol

```swift
import ImageDownloader

struct MyAppConfig: ImageDownloaderConfigProtocol {
    var networkConfig: NetworkConfigProtocol = MyNetworkConfig()
    var cacheConfig: CacheConfigProtocol = MyCacheConfig()
    var storageConfig: StorageConfigProtocol = MyStorageConfig()
    var enableDebugLogging = true
}

struct MyNetworkConfig: NetworkConfigProtocol {
    var maxConcurrentDownloads = 8
    var timeout: TimeInterval = 30
    var retryPolicy = RetryPolicy.aggressive
    var customHeaders: [String: String]? = [
        "User-Agent": "MyApp/1.0"
    ]
    var authenticationHandler: ((inout URLRequest) -> Void)? = { request in
        request.setValue("Bearer \(AuthManager.token)", forHTTPHeaderField: "Authorization")
    }
    var allowsCellularAccess = true
}

struct MyCacheConfig: CacheConfigProtocol {
    var highPriorityCacheSize = 200
    var lowPriorityCacheSize = 500
}

struct MyStorageConfig: StorageConfigProtocol {
    var enableStorage = true
    var compressionProvider: (any ImageCompressionProvider)? = JPEGCompressionProvider(quality: 0.85)
    var pathProvider: (any StoragePathProvider)? = DomainHierarchicalPathProvider()
}

// Usage
let image = try await UIImage.load(from: url, config: MyAppConfig())
```

### App-Wide Configuration Pattern

```swift
import ImageDownloader

extension ImageDownloaderConfigProtocol {
    // Different configs for different use cases
    static let avatar = FastConfig.shared
    static let photo = OfflineFirstConfig.shared
    static let thumbnail = LowMemoryConfig.shared

    // Environment-based config
    static var current: ImageDownloaderConfigProtocol {
        #if DEBUG
        return ConfigBuilder()
            .enableDebugLogging()
            .timeout(60)
            .build()
        #else
        return FastConfig.shared
        #endif
    }
}

// Usage throughout app
avatarImageView.setImage(with: avatarURL, config: .avatar)
photoImageView.setImage(with: photoURL, config: .photo)
thumbImageView.setImage(with: thumbURL, config: .thumbnail)
```

### Per-Environment Configs

```swift
enum Environment {
    case development
    case staging
    case production

    static var current: Environment {
        // Determine from build configuration
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    var imageConfig: ImageDownloaderConfigProtocol {
        switch self {
        case .development:
            return ConfigBuilder()
                .enableDebugLogging()
                .timeout(60)
                .maxConcurrentDownloads(4)
                .build()

        case .staging:
            return ConfigBuilder()
                .timeout(30)
                .maxConcurrentDownloads(6)
                .retryPolicy(.default)
                .build()

        case .production:
            return ConfigBuilder.fast()
                .customHeaders([
                    "X-App-Version": Bundle.main.version
                ])
                .build()
        }
    }
}

// Usage
let config = Environment.current.imageConfig
let image = try await UIImage.load(from: url, config: config)
```

---

## More Examples

For more examples and documentation, see:
- [Complete Documentation](../DOCUMENTATION.md)
- [API Reference](../DOCUMENTATION.md#api-reference)
- [Migration Guide](../DOCUMENTATION.md#migration-guide)
