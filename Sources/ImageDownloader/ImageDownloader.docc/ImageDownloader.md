# ``ImageDownloader``

A powerful, production-ready Swift image downloading library with advanced caching, async/await support, and full customization.

## Overview

ImageDownloader is a modern Swift library for downloading, caching, and managing images in iOS and macOS applications. Built with Swift concurrency, it offers a clean async/await API while maintaining full Objective-C compatibility.

### Key Features

- **Modern Swift Concurrency** - Built-in async/await support
- **Intelligent Caching** - Two-tier memory cache (high/low priority)
- **Persistent Storage** - Automatic disk caching with customizable compression
- **Fully Customizable** - Protocol-based providers for identifiers, paths, and compression
- **Objective-C Compatible** - Full bridging for legacy codebases
- **Production Ready** - Battle-tested architecture with comprehensive error handling

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Configuration>
- <doc:AsyncAwait>

### Customization

- <doc:Customization>
- <doc:CompressionProviders>
- <doc:StorageProviders>

### Advanced

- <doc:ObjectiveCIntegration>
- <doc:MigrationGuide>

### Core Components

- ``ImageDownloaderManager``
- ``ImageDownloaderConfiguration``
- ``ImageResult``
- ``ImageDownloaderError``

### Providers

- ``ResourceIdentifierProvider``
- ``StoragePathProvider``
- ``ImageCompressionProvider``

### UI Integration

- ``AsyncImageView``
- ``NetworkImageView``
