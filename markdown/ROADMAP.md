# ImageDownloader - Roadmap

Simple roadmap for future improvements.

---

## ✅ Completed (v2.0)

- ✅ Retry logic with configurable logging
- ✅ Placeholder & error image support
- ✅ Pure async/await API
- ✅ Image transformations (resize, crop, circle)
- ✅ Background task support
- ✅ Automatic cancellation (SwiftUI & UIKit)
- ✅ Clean public API (~20 types)
- ✅ Thread safety documented

---

## 🎯 Planned Features

### High Priority

**1. Cache Transformed Images**
- Currently: Transforms are applied every time
- Future: Cache by `(URL + transformation.identifier)`
- Benefit: Faster repeated loads

**2. Progressive Image Loading**
- Load low-res placeholder first
- Then load high-res in background
- Smooth UX for large images

**3. WebP Format Support**
- Add WebP decoder
- Better compression than JPEG/PNG
- Widely supported now

### Medium Priority

**4. Memory Pressure Handling**
- Auto-clear low-priority cache on memory warning
- Graceful degradation
- Better system citizen

**5. Prefetch API**
```swift
manager.prefetch(urls: [url1, url2, url3])
```
- Preload images before needed
- Improve perceived performance

**6. Animated Image Support (GIF, APNG)**
- Support for animated formats
- Control animation playback
- Memory-efficient loading

### Low Priority

**7. Image Processing Pipeline**
```swift
ImagePipeline()
    .resize(to: size)
    .blur(radius: 10)
    .adjustBrightness(0.2)
    .apply(to: image)
```

**8. CDN Integration Helpers**
- URL builders for common CDNs (Cloudinary, Imgix)
- Auto-sizing based on device
- Format selection

**9. Network Quality Adaptation**
- Lower quality on slow networks
- Higher quality on WiFi
- Automatic adjustment

---

## �� Performance Improvements

1. **Faster disk I/O** - Use memory-mapped files for cache
2. **Better deduplication** - Track in-flight requests more efficiently
3. **Smarter cache eviction** - LRU + frequency-based eviction
4. **Reduce allocations** - Object pooling for common types

---

## 📚 Documentation

1. **Video tutorials** - Screen recordings for common use cases
2. **Migration guide from SDWebImage/Kingfisher**
3. **Performance benchmarks** - Compare with other libraries

---

## 🚫 Not Planned

- ❌ Video/audio support (out of scope)
- ❌ Built-in image filters (use CoreImage)
- ❌ Social media integration (use specific libraries)

---

## Contributing

Have ideas? Open an issue or PR! We focus on:
- **Simplicity** - Easy to use and integrate
- **Performance** - Fast and efficient
- **Reliability** - Well-tested and stable
