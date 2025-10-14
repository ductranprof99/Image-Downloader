# ImageDownloader Library - Sequence Diagrams (Modular)

## Overview

This document contains the complete flow broken down into 6 smaller, manageable sequence diagrams:

1. **Cache Hit Flow** - Fastest path, image in memory
2. **Cache Wait Flow** - Request deduplication when download in progress
3. **Storage Hit Flow** - Cache miss but image on disk
4. **Network Download Flow** - Full download from network
5. **Network Request Management** - Concurrency control & deduplication
6. **Download Success Processing** - Save to storage and cache

---

## 1. Cache Hit Flow (Simple & Fast)

```mermaid
sequenceDiagram
    actor User
    participant UI as UIImageView
    participant Manager as ImageDownloaderManager
    participant Cache as CacheAgent (Actor)
    participant Storage as StorageAgent

    User->>UI: Display Image
    UI->>Manager: requestImage(url)

    Manager->>Cache: await image(for: url)
    activate Cache
    Cache-->>Manager: .hit(UIImage)
    deactivate Cache

    Note over Manager: Optional: Save to storage<br/>if not already saved

    alt Storage doesn't have image
        Manager->>Storage: saveImage(image, url)
        Note over Storage: Background save
    end

    Manager->>UI: completion(image, fromCache: true)
    UI->>User: Display Image ✓
```

---

## 2. Cache Wait Flow (Request Deduplication)

```mermaid
sequenceDiagram
    actor User1
    actor User2
    participant UI1 as UIImageView 1
    participant UI2 as UIImageView 2
    participant Manager as ImageDownloaderManager
    participant Cache as CacheAgent (Actor)
    participant Registry as CallerRegistry<br/>(WeakBox + NSLock)

    User1->>UI1: Display Image
    UI1->>Manager: requestImage(url)

    Manager->>Cache: await image(for: url)
    activate Cache
    Cache-->>Manager: .wait
    Note over Cache: Download already in progress<br/>by another request
    deactivate Cache

    Manager->>Registry: registerCaller(url, caller: UI1, completion)
    activate Registry
    Registry-->>Registry: Store weak reference
    Note over Registry: Avoids retain cycles
    deactivate Registry

    Note over User2: Meanwhile, another request<br/>for same URL arrives

    User2->>UI2: Display Same Image
    UI2->>Manager: requestImage(url)
    Manager->>Cache: await image(for: url)
    activate Cache
    Cache-->>Manager: .wait
    deactivate Cache

    Manager->>Registry: registerCaller(url, caller: UI2, completion)
    activate Registry
    Registry-->>Registry: Add to waiters list
    deactivate Registry

    Note over Manager,Registry: When download completes,<br/>all waiters notified

    Manager->>Registry: notifyCallers(url, image)
    activate Registry
    loop For each waiting caller
        Registry->>UI1: completion(image)
        Registry->>UI2: completion(image)
    end
    deactivate Registry

    UI1->>User1: Display Image ✓
    UI2->>User2: Display Image ✓
```

---

## 3. Storage Hit Flow (Disk Cache)

```mermaid
sequenceDiagram
    actor User
    participant UI as UIImageView
    participant Manager as ImageDownloaderManager
    participant Cache as CacheAgent (Actor)
    participant Storage as StorageAgent

    User->>UI: Display Image
    UI->>Manager: requestImage(url)

    Manager->>Cache: await image(for: url)
    activate Cache
    Cache-->>Manager: .miss
    Note over Cache: Creates placeholder entry<br/>to prevent duplicate downloads
    deactivate Cache

    Note over Manager: Check storage before<br/>downloading from network

    Manager->>Storage: image(for: url)
    activate Storage
    Note over Storage: Read from disk<br/>(FileManager + Decompression)
    Storage-->>Manager: UIImage ✓
    deactivate Storage

    Note over Manager: Update cache for next time

    Manager->>Cache: await setImage(image, url, isHighLatency)
    activate Cache
    Cache-->>Cache: Add to LRU queue
    Cache-->>Cache: Evict if over limit
    deactivate Cache

    Manager->>UI: completion(image, fromStorage: true)
    UI->>User: Display Image ✓
```

---

## 4. Network Download Flow (Full Path)

```mermaid
sequenceDiagram
    actor User
    participant UI as UIImageView
    participant Manager as ImageDownloaderManager
    participant Cache as CacheAgent (Actor)
    participant Storage as StorageAgent
    participant Network as NetworkAgent

    User->>UI: Display Image
    UI->>Manager: requestImage(url)

    Manager->>Cache: await image(for: url)
    activate Cache
    Cache-->>Manager: .miss
    deactivate Cache

    Manager->>Storage: image(for: url)
    activate Storage
    Storage-->>Manager: nil (not found)
    deactivate Storage

    Note over Manager: Must download from network

    Manager->>Network: downloadData(url, priority, completion)
    activate Network
    Note over Network: See Diagram 5:<br/>Network Request Management
    Network-->>Manager: completion(image, nil)
    deactivate Network

    Note over Manager: See Diagram 6:<br/>Download Success Processing

    Manager->>UI: completion(image, fromCache: false, fromStorage: false)
    UI->>User: Display Image ✓
```

---

## 5. Network Request Management (Concurrency Control)

```mermaid
sequenceDiagram
    participant Manager as ImageDownloaderManager
    participant Network as NetworkAgent
    participant Queue as PendingQueue
    participant URLSession

    Manager->>Network: downloadData(url, priority)
    activate Network

    Network->>Network: isolationQueue.async
    Note over Network: Serial queue ensures<br/>thread-safe state access

    alt Request Already Downloading (Deduplication)
        Network-->>Network: Check activeDownloads[url]
        Network-->>Network: Join existing DownloadTask
        Note over Network: Multiple requests share<br/>one network call
        Network-->>Manager: (Will notify when complete)

    else Concurrency Limit Reached
        Network->>Queue: Add to pendingQueue
        activate Queue
        Note over Queue: Priority-based insertion:<br/>high priority goes first
        deactivate Queue
        Network-->>Manager: (Queued, will start later)

    else Slot Available - Start Download
        Network->>Network: Create DownloadTask
        Network->>Network: Add to activeDownloads

        Network->>URLSession: dataTask(with: request)
        activate URLSession
        Note over URLSession: Background download

        URLSession-->>Network: Download progress
        Network->>Manager: progress callback

        URLSession-->>Network: Data received ✓
        deactivate URLSession

        Network->>Network: Decode image (background)
        Network->>Network: Remove from activeDownloads

        Network->>Queue: processNextPendingUnsafe()
        activate Queue
        Note over Queue: Start next download<br/>from pending queue
        deactivate Queue

        Network-->>Manager: completion(image, nil)
    end
    deactivate Network
```

---

## 6. Download Success Processing (Save & Cache)

```mermaid
sequenceDiagram
    participant Manager as ImageDownloaderManager
    participant Storage as StorageAgent
    participant Cache as CacheAgent (Actor)
    participant Registry as CallerRegistry
    participant UI as UIImageView

    Note over Manager: Image downloaded successfully<br/>from network

    Manager->>Manager: processDownloadedImage()

    par Save to Storage (Background Thread)
        Manager->>Storage: saveImage(image, url)
        activate Storage
        Note over Storage: DispatchQueue.global()<br/>1. Create subdirectories<br/>2. Compress image<br/>3. Write atomically
        deactivate Storage

    and Update Cache (Actor - Thread Safe)
        Manager->>Cache: await setImage(image, url, isHighLatency)
        activate Cache
        Cache-->>Cache: Update cacheData[url]
        Cache-->>Cache: Append to LRU queue
        Cache-->>Cache: evictMemory() if needed
        Note over Cache: Evict least recently used
        deactivate Cache
    end

    Note over Manager: Notify all waiters

    Manager->>Manager: notifySuccess(url, image)

    par Notify Original Caller
        Manager->>UI: completion(image, nil)

    and Notify All Waiting Callers
        Manager->>Registry: notifyCallers(url, image)
        activate Registry
        Registry-->>Registry: Get all waiters
        Registry-->>Registry: Filter alive callers
        Registry-->>Registry: Remove URL from registry
        loop For each waiting caller
            Registry->>UI: completion(image, nil)
        end
        deactivate Registry
    end

    Note over Manager,UI: All requests satisfied ✓
```

---

## 7. Error Handling & Retry Flow

```mermaid
sequenceDiagram
    participant Network as NetworkAgent
    participant URLSession
    participant RetryPolicy
    participant Manager as ImageDownloaderManager

    Network->>URLSession: dataTask(with: request)
    activate URLSession

    URLSession-->>Network: Error ✗
    deactivate URLSession

    Network->>RetryPolicy: shouldRetry(error, attempt)
    activate RetryPolicy

    alt Should Retry
        RetryPolicy-->>Network: true + delay

        Note over Network: Exponential backoff:<br/>delay = baseDelay × 2^attempt

        Network->>Network: asyncAfter(delay)

        Network->>URLSession: Retry download (attempt + 1)
        activate URLSession
        Note over URLSession: Try again...

        alt Retry Success
            URLSession-->>Network: Data received ✓
            Network-->>Manager: completion(image, nil)

        else Retry Failed Again
            URLSession-->>Network: Error again ✗
            Note over Network: Continue retry loop<br/>or give up
        end
        deactivate URLSession

    else Should NOT Retry (Max attempts reached)
        RetryPolicy-->>Network: false

        Network->>Network: notifyAllWaiters(nil, error)
        Network-->>Manager: completion(nil, error)

        Manager->>Manager: notifyFailure(url, error)
        Manager->>UI: completion(nil, error)
    end
    deactivate RetryPolicy
```

---

## Flow Decision Tree

```
User requests image
    ↓
Check Cache
    ├─ HIT  → Return immediately ✓ (Diagram 1)
    ├─ WAIT → Join existing download (Diagram 2)
    └─ MISS → Continue
         ↓
    Check Storage
         ├─ HIT  → Load from disk, update cache ✓ (Diagram 3)
         └─ MISS → Continue
              ↓
         Download from Network (Diagram 4)
              ├─ Check concurrency (Diagram 5)
              │    ├─ Already downloading → Join
              │    ├─ Queue full → Add to pending
              │    └─ Slot available → Start download
              │         ↓
              │    Download & Decode
              │         ├─ Success → Process (Diagram 6)
              │         └─ Error → Retry (Diagram 7)
              ↓
         Save to storage + Update cache (Diagram 6)
              ↓
         Notify all waiters ✓
```

---

## Component Responsibilities Summary

| Component | Responsibility | Thread Safety |
|-----------|---------------|---------------|
| **CacheAgent** | Two-tier LRU memory cache | Swift Actor |
| **StorageAgent** | Disk persistence with compression | Background Queue |
| **NetworkAgent** | Download management & concurrency | Serial DispatchQueue |
| **CallerRegistry** | Track waiting callers with weak refs | NSLock |
| **PendingQueue** | Priority-based download queue | Part of NetworkAgent |
| **RetryPolicy** | Retry strategy & backoff | Stateless |

---

## Key Features Highlighted

1. **Request Deduplication** (Diagram 2) - Multiple requests share one download
2. **Concurrency Control** (Diagram 5) - Max simultaneous downloads with priority queue
3. **Three-tier Caching** (Diagrams 1, 3, 4) - Memory → Disk → Network
4. **Weak References** (Diagram 2) - Automatic cleanup when views deallocated
5. **Parallel Processing** (Diagram 6) - Storage save & cache update in parallel
6. **Retry Logic** (Diagram 7) - Exponential backoff for failed downloads

---

## Testing Each Diagram

Each diagram can be tested independently:

- **Diagram 1**: Test with cached images
- **Diagram 2**: Make multiple simultaneous requests for same URL
- **Diagram 3**: Clear cache, keep storage
- **Diagram 4-6**: Clear cache and storage
- **Diagram 7**: Test with invalid URLs or network errors

This modular approach makes debugging and understanding much easier!
