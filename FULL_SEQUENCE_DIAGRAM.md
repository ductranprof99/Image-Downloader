# ImageDownloader Library - Simplified Combined Sequence Diagram

## Unified Flow 

```mermaid
sequenceDiagram
    autonumber
    actor View
    participant Manager as ImageDownloader Manager
    participant Cache
    participant Storage
    participant Network
    participant Decoder

    View->>Manager: requestImage(url, completion)
    Manager->>Cache: getImageInCache(for url)
    alt Cache HIT
        Cache-->>Manager: image
        Manager-->>View: completion(image, fromCache=true)
    else Cache WAIT (duplicate)
        Cache-->>Manager: wait
        Manager->>Manager: joinExistingRequest(for url)
        note over Manager: Completion delivered when ongoing download finishes
    else Cache MISS
        Cache-->>Manager: miss

        alt Storage enabled
            Manager->>Storage: getImageInStorage(for url)
            alt Storage HIT
                Storage-->>Manager: image
                Manager->>Cache: saveToCache(image)
                Cache-->>Manager: ok
                Manager-->>View: completion(image, fromStorage=true)
            else Storage MISS
                Storage-->>Manager: nil
                Manager->>Network: downloadImage(for url)
                alt Joined existing download
                    Network-->>Manager: joined
                    note over Manager: Wait for existing download result
                else New download
                    Network-->>Manager: data or error
                end

                alt Download success
                    Manager->>Decoder: decodeImage(from data)
                    Decoder-->>Manager: image
                    opt Save to storage enabled
                        Manager->>Storage: saveToStorage(image, for url)
                        Storage-->>Manager: ok
                    end
                    Manager->>Cache: saveToCache(image)
                    Cache-->>Manager: ok
                    Manager-->>View: completion(image)
                else Download failure
                    Manager-->>View: completion(error)
                end
            end
        else Storage disabled
            Manager->>Network: downloadImage(for url)
            alt Joined existing download
                Network-->>Manager: joined
                note over Manager: Wait for existing download result
            else New download
                Network-->>Manager: data or error
            end

            alt Download success
                Manager->>Decoder: decodeImage(from data)
                Decoder-->>Manager: image
                Manager->>Cache: saveToCache(image)
                Cache-->>Manager: ok
                Manager-->>View: completion(image)
            else Download failure
                Manager-->>View: completion(error)
            end
        end
    end
```

## Key Components Interaction Details

### 1. **ImageDownloaderManager** (Coordinator)
- Entry point for all image requests
- Manages caller registry for request deduplication
- Coordinates between Cache, Storage, and Network agents
- Ensures all callbacks run on main thread
- Periodic cleanup of dead callers (30s timer)

### 2. **CacheAgent** (Swift Actor - Thread Safe)
- Two-tier LRU cache (high/low latency)
- Three states: HIT, WAIT, MISS
- Actor isolation ensures thread-safe access
- Automatic eviction when limits exceeded
- WAIT state prevents duplicate downloads

### 3. **StorageAgent** (Synchronous FileManager)
- Disk persistence with customizable:
  - Identifier Provider (MD5/SHA256)
  - Path Provider (Flat/Hierarchical)
  - Compression Provider (PNG/JPEG/Adaptive)
- All I/O on background threads
- Atomic write operations

### 4. **NetworkAgent** (Serial Queue for Thread Safety)
- **Request Deduplication**: Multiple requests for same URL share one download
- **Concurrency Limiting**: Max simultaneous downloads (default: 6)
- **Priority Queue**: High-priority requests jump ahead in pending queue
- **Retry Policy**: Configurable attempts with exponential backoff
- **Progress Tracking**: Real-time download progress callbacks
- Downloads RAW data only - decoding separate

### 5. **CallerRegistry** (Weak References + NSLock)
- Stores waiting callers for images being downloaded
- Uses WeakBox to avoid retain cycles
- Thread-safe with NSLock
- Periodic cleanup removes dead callers
- Notifies all waiters when download completes

### 6. **ImageDecoder** (Background Decoding)
- Decodes images on background thread
- Prevents main thread blocking
- Returns UIImage ready for display

### 7. **PendingQueue** (Priority FIFO)
- Holds downloads waiting for available slots
- High-priority requests inserted before low-priority
- Processed when active downloads complete
- Prevents memory exhaustion from unlimited concurrent downloads

## Thread Safety Mechanisms

| Component | Mechanism | Purpose |
|-----------|-----------|---------|
| CacheAgent | Swift Actor | Automatic serialization of all cache operations |
| NetworkAgent | Serial DispatchQueue | Thread-safe state management (activeDownloads, pendingQueue) |
| CallerRegistry | NSLock | Protect concurrent access to registry dictionary |
| StorageAgent | Background Queue | All FileManager I/O on background threads |
| Callbacks | DispatchQueue.main | All completion blocks run on main thread |

## Performance Optimizations

1. **Request Deduplication**: Saves 50-90% bandwidth in list/grid views
2. **Concurrency Limiting**: Prevents resource exhaustion
3. **Priority Queue**: Important images load first
4. **Two-Tier Cache**: High-latency for persistent, low-latency for transient
5. **Background Decoding**: Smooth scrolling, no main thread blocking
6. **LRU Eviction**: Automatic memory management
7. **Lazy Storage**: Only saves to disk if configured
8. **Weak References**: Automatic cleanup when views deallocated
9. **Actor-based Cache**: Lock-free concurrent reads

## Error Handling & Edge Cases

1. **Cancelled Requests**: Properly cleaned up, no memory leaks
2. **Dead Callers**: Periodic cleanup every 30s removes WeakBox with nil value
3. **Network Failures**: Retry with exponential backoff (configurable)
4. **Timeout**: Configurable per-request timeout
5. **Invalid Data**: Graceful error handling with typed errors
6. **Background Task**: Downloads continue when app backgrounded (if enabled)
7. **Memory Pressure**: LRU eviction based on configurable limits

## Configuration Points

All configurable via `ConfigBuilder`:

- **Network**: maxConcurrentDownloads, timeout, retryPolicy, customHeaders, authHandler
- **Cache**: highLatencyLimit, lowLatencyLimit
- **Storage**: enableSaveToStorage, identifierProvider, pathProvider, compressionProvider
- **Retry**: maxAttempts, baseDelay, multiplier (exponential backoff)

## Example Flow Summary

**Scenario**: User scrolls list with 100 images, 10 visible

1. **First request**: Cache MISS → Storage MISS → Network download starts
2. **Same URL requested again**: Cache WAIT → Joins existing download (deduplication)
3. **10 concurrent downloads**: Slots 1-6 active, slots 7-10 in pending queue
4. **User scrolls away**: UIImageView deallocated → Weak reference becomes nil → Auto cleanup
5. **Download completes**: All waiters notified → Next pending starts → Cached for future

This architecture provides production-ready image loading with excellent performance, thread safety, and resource management.
