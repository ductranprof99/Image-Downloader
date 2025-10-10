# Image Downloader Library - Architecture Diagrams

## 1. Work Flow Diagram (Request Flow)

```mermaid
graph LR
    A[User Request Image] --> B[ImageDownloaderManager]
    B --> C{Check Cache?}

    C -->|HIT| D[Return Image<br/>fromCache: true]
    C -->|WAIT| E[Register Caller<br/>in Registry]
    C -->|MISS| F{Storage Enabled?}

    F -->|Yes| G{Check Storage?}
    F -->|No| J[NetworkAgent]

    G -->|Found| H[Load from Storage]
    G -->|Not Found| J

    H --> I[Update Cache<br/>with Latency]
    I --> K[Return Image<br/>fromStorage: true]

    J --> L{Request<br/>Deduplication?}
    L -->|Already Downloading| M[Join Existing Task]
    L -->|New Request| N{Concurrency<br/>Limit?}

    N -->|Slots Available| O[Start Download]
    N -->|Queue Full| P[Add to Pending Queue<br/>Priority-based]

    O --> Q[URLSession Download]
    Q --> R{Retry Policy?}
    R -->|Error & Should Retry| O
    R -->|Success| S[Decode Image]

    S --> T[Save to Storage<br/>Background Thread]
    T --> U[Update Cache<br/>with Latency]
    U --> V[Notify All Waiters<br/>Main Thread]
    V --> W[Return Image<br/>fromCache: false]

    M --> V
    P --> X[Process Next<br/>when slot available]
    X --> O

    style D fill:#90EE90
    style K fill:#90EE90
    style W fill:#90EE90
    style B fill:#4169E1,color:#fff
    style C fill:#FFD700
    style F fill:#FFD700
    style G fill:#FFD700
    style L fill:#FFD700
    style N fill:#FFD700
    style R fill:#FFD700
```

## 2. Thread/Concurrency Diagram

```mermaid
graph LR
    subgraph MainThread["🧵 Main Thread"]
        A1[User Code] --> A2[requestImage]
        A2 --> A3[Completion Block<br/>Image Display]
    end

    subgraph ManagerQueue["🧵 Manager Queue<br/>com.imagedownloader.manager.queue"]
        M1[Caller Registry<br/>NSLock]
        M2[Timer: Cleanup<br/>Dead Callers 30s]
    end

    subgraph CacheActor["⚡ Cache Actor<br/>Thread-Safe Actor"]
        C1[image for URL] --> C2{Result}
        C2 -->|HIT| C3[Return UIImage]
        C2 -->|WAIT| C4[Return Wait State]
        C2 -->|MISS| C5[Create Placeholder]

        C6[setImage] --> C7[Update cacheData]
        C7 --> C8[Update LRU Queue]
        C8 --> C9[Evict if Over Limit]
    end

    subgraph NetworkQueue["🧵 Network Isolation Queue<br/>com.imagedownloader.networkagent.isolation"]
        N1[activeDownloads<br/>Dictionary]
        N2[pendingQueue<br/>Priority FIFO]
        N3[Request<br/>Deduplication]
        N4[Concurrency<br/>Control]
    end

    subgraph BackgroundThreads["🧵 Background Threads<br/>DispatchQueue.global"]
        B1[Download Task 1] --> B2[URLSession]
        B3[Download Task 2] --> B2
        B4[Download Task N] --> B2

        B5[Image Decode] --> B6[Save to Storage<br/>FileManager]
    end

    subgraph StorageSync["💾 Storage Agent<br/>Synchronous FileManager"]
        S1[Read/Write<br/>Disk I/O]
    end

    A2 -.->|Task| CacheActor
    CacheActor -.->|await| A2

    A2 --> N1
    N1 --> N3
    N3 --> N4
    N4 -.->|Start Download| BackgroundThreads

    BackgroundThreads -.->|Completion| NetworkQueue
    NetworkQueue -.->|Process Next| BackgroundThreads

    BackgroundThreads --> B5
    B5 -.->|Background Thread| S1
    B5 -.->|await| CacheActor
    B5 -.->|DispatchQueue.main| MainThread

    M2 --> M1
    A2 -.->|Register| M1

    style MainThread fill:#E6F3FF
    style ManagerQueue fill:#FFE6E6
    style CacheActor fill:#E6FFE6
    style NetworkQueue fill:#FFF9E6
    style BackgroundThreads fill:#F0E6FF
    style StorageSync fill:#FFE6F0
```

## 3. Component Detail Diagram

```mermaid
graph LR
    subgraph PublicAPI["📱 Public API Layer"]
        API1[ImageDownloaderManager<br/>Singleton/Factory]
        API2[IDConfiguration<br/>ConfigBuilder]
        API3[UI Extensions<br/>UIImageView+<br/>AsyncImageView]
    end

    subgraph CoreAgents["🎯 Core Agents"]
        subgraph CacheSystem["Memory Cache"]
            CA1[CacheAgent<br/>Actor]
            CA2[Two-Tier LRU<br/>High/Low Latency]
            CA3[CacheEntry<br/>URL + Image + Priority]
            CA4[Eviction Policy<br/>Configurable Limits]
        end

        subgraph NetworkSystem["Network Layer"]
            NA1[NetworkAgent<br/>Serial Queue]
            NA2[Request Deduplication<br/>URL-based]
            NA3[Concurrency Control<br/>Max Downloads]
            NA4[Priority Queue<br/>High/Low Priority]
            NA5[Retry Policy<br/>Configurable Attempts]
            NA6[URLSession<br/>Shared Instance]
            NA7[ImageDecoder<br/>Background Decode]
        end

        subgraph StorageSystem["Disk Storage"]
            SA1[StorageAgent<br/>Synchronous]
            SA2[FileManager<br/>Read/Write]
            SA3[Identifier Provider<br/>MD5/SHA256]
            SA4[Path Provider<br/>Flat/Hierarchical]
            SA5[Compression Provider<br/>PNG/JPEG/Adaptive]
        end
    end

    subgraph Configuration["⚙️ Configuration System"]
        CF1[IDNetworkConfig<br/>Timeout/Headers/Auth]
        CF2[IDCacheConfig<br/>Limits/Memory Policy]
        CF3[IDStorageConfig<br/>Path/Compression]
        CF4[RetryPolicy<br/>Aggressive/Conservative]
    end

    subgraph Helpers["🔧 Helper Components"]
        H1[WeakBox<br/>Caller Registry]
        H2[DownloadTask<br/>Task Wrapper]
        H3[DownloadProgress<br/>Speed/Bytes]
        H4[SessionDelegate<br/>URLSession Callbacks]
        H5[Image Transformations<br/>Resize/Crop/Circle]
    end

    subgraph Models["📦 Data Models"]
        M1[CacheFetchResult<br/>Hit/Wait/Miss]
        M2[ImageDownloaderError<br/>Typed Errors]
        M3[ResourceUpdateLatency<br/>High/Low]
        M4[DownloadPriority<br/>High/Low]
    end

    API1 --> API2
    API1 --> CA1
    API1 --> NA1
    API1 --> SA1
    API1 --> H1

    API2 --> CF1
    API2 --> CF2
    API2 --> CF3

    CA1 --> CA2
    CA2 --> CA3
    CA2 --> CA4

    NA1 --> NA2
    NA1 --> NA3
    NA1 --> NA4
    NA4 --> NA5
    NA1 --> NA6
    NA6 --> H4
    NA1 --> NA7
    NA1 --> H2
    H2 --> H3

    SA1 --> SA2
    SA1 --> SA3
    SA1 --> SA4
    SA1 --> SA5

    CF1 --> CF4

    API1 --> M1
    API1 --> M2
    API1 --> M3
    API1 --> M4

    API3 --> API1
    API3 --> H5

    style PublicAPI fill:#4169E1,color:#fff
    style CoreAgents fill:#2E8B57,color:#fff
    style Configuration fill:#FF8C00,color:#fff
    style Helpers fill:#9370DB,color:#fff
    style Models fill:#DC143C,color:#fff

    style CacheSystem fill:#90EE90
    style NetworkSystem fill:#87CEEB
    style StorageSystem fill:#FFB6C1
```

## 4. User API - Simple Usage Diagram

```mermaid
graph LR
    User[👤 User Code] --> Manager[ImageDownloaderManager]

    Manager --> Request[requestImage]
    Request --> Callback[Completion Block<br/>image, error, fromCache, fromStorage]

    Manager --> Cache[Cache Control]
    Cache --> ClearCache[clearCache / clearAllCache]
    Cache --> GetCount[Cache Count]

    Manager --> Storage[Storage Control]
    Storage --> ClearStorage[clearStorage]
    Storage --> GetPath[storagePath]

    style User fill:#4169E1,color:#fff
    style Manager fill:#2E8B57,color:#fff
    style Request fill:#FFD700
    style Cache fill:#87CEEB
    style Storage fill:#FFB6C1
```

## 5. Configuration - Simple Setup Diagram

```mermaid
graph LR
    User[👤 User] --> Builder[ConfigBuilder]

    Builder --> Network[Network Config]
    Network --> N1[maxConcurrentDownloads]
    Network --> N2[timeout]
    Network --> N3[retryPolicy]
    Network --> N4[customHeaders]

    Builder --> Cache[Cache Config]
    Cache --> C1[highLatencyLimit]
    Cache --> C2[lowLatencyLimit]

    Builder --> Storage[Storage Config]
    Storage --> S1[enableSaveToStorage]
    Storage --> S2[identifierProvider<br/>MD5/SHA256]
    Storage --> S3[pathProvider<br/>Flat/Hierarchical]
    Storage --> S4[compressionProvider<br/>PNG/JPEG/Adaptive]

    Builder --> Build[build]
    Build --> Config[IDConfiguration]
    Config --> Manager[ImageDownloaderManager.instance]

    style User fill:#4169E1,color:#fff
    style Builder fill:#2E8B57,color:#fff
    style Network fill:#87CEEB
    style Cache fill:#90EE90
    style Storage fill:#FFB6C1
    style Config fill:#FF8C00,color:#fff
    style Manager fill:#DC143C,color:#fff
```

## 6. Quick Start - Three Steps

```mermaid
graph LR
    Step1[1️⃣ Get Manager] --> Step2[2️⃣ Request Image] --> Step3[3️⃣ Display Result]

    Step1 --> S1A[ImageDownloaderManager.shared]
    Step1 --> S1B[ImageDownloaderManager.instance<br/>with custom config]

    Step2 --> S2A[manager.requestImage<br/>url, completion]

    Step3 --> S3A[imageView.image = image]

    style Step1 fill:#4169E1,color:#fff
    style Step2 fill:#2E8B57,color:#fff
    style Step3 fill:#FF8C00,color:#fff
```

## 7. UI Helpers - Easy Integration

```mermaid
graph LR
    User[👤 User] --> UIKit[UIKit]
    User --> SwiftUI[SwiftUI]

    UIKit --> Extension[UIImageView Extension]
    Extension --> E1[setImage with URL]
    Extension --> E2[Placeholder Support]
    Extension --> E3[Auto Cancellation]

    UIKit --> AsyncView[UIAsyncImageView]
    AsyncView --> A1[Custom UIImageView]
    AsyncView --> A2[Progress Tracking]
    AsyncView --> A3[Error Handling]

    SwiftUI --> SUI1[AsyncImageView]
    SUI1 --> S1[Progress Bar]
    SUI1 --> S2[Placeholder/Error Images]
    SUI1 --> S3[Auto Cancel on Disappear]

    SwiftUI --> SUI2[ProgressiveAsyncImage]
    SUI2 --> P1[Progressive Loading]
    SUI2 --> P2[Custom Content Builder]

    UIKit --> Transform[Image Transformations]
    SwiftUI --> Transform
    Transform --> T1[Resize]
    Transform --> T2[Crop]
    Transform --> T3[Circle/RoundedCorners]
    Transform --> T4[Composite Multiple]

    style User fill:#4169E1,color:#fff
    style UIKit fill:#2E8B57,color:#fff
    style SwiftUI fill:#FF8C00,color:#fff
    style Extension fill:#87CEEB
    style AsyncView fill:#90EE90
    style SUI1 fill:#FFB6C1
    style SUI2 fill:#DDA0DD
    style Transform fill:#F0E68C
```

## Key Features Summary

### 1. Three-Layer Architecture
- **Cache Layer**: Two-tier LRU cache (High/Low latency) using Swift Actor for thread safety
- **Storage Layer**: Disk persistence with customizable providers (identifier, path, compression)
- **Network Layer**: Concurrent downloads with retry policy and request deduplication

### 2. Thread Safety
- **Cache**: Swift Actor with automatic serialization
- **Network**: Serial DispatchQueue for state management
- **Manager**: NSLock for caller registry
- **Storage**: Synchronous FileManager operations

### 3. Smart Request Handling
- **Deduplication**: Multiple requests for same URL join single download
- **Caller Registry**: Weak references to avoid retain cycles
- **Priority Queue**: High-priority requests jump ahead
- **Concurrency Limit**: Configurable max simultaneous downloads

### 4. Extensibility
- **Protocol-based Providers**: Custom identifier, path, and compression strategies
- **Configuration Builder**: Fluent API for easy setup
- **Retry Policy**: Pluggable retry strategies
- **UI Extensions**: Ready-to-use SwiftUI and UIKit components

### 5. Performance Optimizations
- **Background Decoding**: Images decoded off main thread
- **LRU Eviction**: Automatic memory management
- **Request Coalescing**: Reduces duplicate network calls
- **Lazy Storage**: Only saves to disk if configured
