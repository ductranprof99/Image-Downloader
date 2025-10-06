# Compression Providers

Choose how images are compressed for storage.

## Available Providers

### PNGCompressionProvider (Default)

Lossless compression, larger files:

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: PNGCompressionProvider()
)
```

**Pros:** Perfect quality, no artifacts
**Cons:** Larger file sizes (2-5x vs JPEG)
**Best for:** Icons, logos, UI elements

### JPEGCompressionProvider

Lossy compression, much smaller files:

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: JPEGCompressionProvider(quality: 0.8)
)
```

**Pros:** 50-80% smaller files, fast
**Cons:** Quality loss, artifacts at low quality
**Best for:** Photos, large images
**Quality:** 0.8 recommended (0.0 = max compression, 1.0 = max quality)

### AdaptiveCompressionProvider

Automatically chooses PNG or JPEG:

```swift
let config = ImageDownloaderConfiguration(
    compressionProvider: AdaptiveCompressionProvider(
        sizeThresholdMB: 1.0,
        jpegQuality: 0.85
    )
)
```

**How it works:**
1. Try PNG first
2. If PNG > threshold, use JPEG
3. Store smaller result

**Best for:** Mixed content apps (recommended for production)

## Comparison

| Provider | File Size | Quality | Speed | Best For |
|----------|-----------|---------|-------|----------|
| PNG | 100% | Perfect | Medium | Icons, UI |
| JPEG 0.9 | 40% | Excellent | Fast | Photos |
| JPEG 0.8 | 30% | Good | Fast | General use |
| JPEG 0.6 | 20% | Fair | Fast | Max compression |
| Adaptive | 40% | Smart | Medium | **Production** |

## Topics

### Types

- ``ImageCompressionProvider``
- ``PNGCompressionProvider``
- ``JPEGCompressionProvider``
- ``AdaptiveCompressionProvider``
