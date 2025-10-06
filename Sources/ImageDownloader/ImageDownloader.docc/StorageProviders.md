# Storage Providers

Organize image files on disk.

## Available Providers

### FlatStoragePathProvider (Default)

All files in single directory:

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: FlatStoragePathProvider()
)
```

**Structure:** `ImageDownloaderStorage/abc123_image.png`
**Best for:** <1000 images, simple apps

### DomainHierarchicalPathProvider

Organize by domain:

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DomainHierarchicalPathProvider()
)
```

**Structure:** `ImageDownloaderStorage/example.com/abc123.png`
**Best for:** Multiple sources, 1000+ images

### DateHierarchicalPathProvider

Organize by download date:

```swift
let config = ImageDownloaderConfiguration(
    pathProvider: DateHierarchicalPathProvider()
)
```

**Structure:** `ImageDownloaderStorage/2025/10/06/abc123.png`
**Best for:** Time-based analysis, archival

## Performance

| Provider | File Lookup Speed | Best For |
|----------|------------------|----------|
| Flat | Good (<1K) | Simple apps |
| Domain | Excellent (10K+) | Multi-source |
| Date | Excellent (10K+) | Time-based |

## Topics

### Types

- ``StoragePathProvider``
- ``FlatStoragePathProvider``
- ``DomainHierarchicalPathProvider``
- ``DateHierarchicalPathProvider``
