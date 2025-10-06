# CNI (Custom Network Image) Library - Improvement Plan

## Current Architecture Analysis

### Existing Components
```
CNI/
├── Manager/        - CNIManager (Singleton coordinator)
├── CacheAgent/     - In-memory cache (High/Low priority)
├── NetworkAgent/   - Download manager with queue
├── StorageAgent/   - Disk persistence
├── Observer/       - Event notification system
└── Model/          - CNIResourceModel (state management)
```

---

## 📋 Task List for CNI Improvements

### **Task 1: Protocol-Based Multi-Framework Adapter**
Create protocol layer to support UIKit, SwiftUI, ComponentKit, and Objective-C

**Subtasks:**
- [ ] 1.1 - Design `CNIImageViewProtocol` for framework-agnostic interface
- [ ] 1.2 - Create UIKit adapter (`CNIUIKitImageView`)
- [ ] 1.3 - Create SwiftUI adapter (`CNIImageView` struct)
- [ ] 1.4 - Create ComponentKit adapter (refactor `CustomNetworkImageView`)
- [ ] 1.5 - Create vanilla Objective-C adapter (`CNIObjCImageView`)
- [ ] 1.6 - Document adapter pattern and usage examples

### **Task 2: File Control System with Inheritance/Override**
Implement configuration system with hierarchical overrides

**Subtasks:**
- [ ] 2.1 - Design `CNIConfiguration` protocol
- [ ] 2.2 - Create `CNIBaseConfiguration` (global defaults)
- [ ] 2.3 - Create `CNIRequestConfiguration` (per-request overrides)
- [ ] 2.4 - Implement configuration merging/inheritance logic
- [ ] 2.5 - Add configuration validation
- [ ] 2.6 - Create configuration builder pattern

### **Task 3: Network Layer Improvements**
Enhance networking capabilities

**Subtasks:**
- [ ] 3.1 - Add retry mechanism with exponential backoff
- [ ] 3.2 - Implement request deduplication
- [ ] 3.3 - Add support for custom headers/authentication
- [ ] 3.4 - Implement bandwidth throttling
- [ ] 3.5 - Add WebP/AVIF format support
- [ ] 3.6 - Implement progressive image loading
- [ ] 3.7 - Add request interceptor pattern
- [ ] 3.8 - Network reachability monitoring

---

## 🎯 Task 1: Protocol-Based Multi-Framework Adapter

### Design

#### Core Protocol
```objc
@protocol CNIImageViewAdapter <NSObject>

@required
// Set the image
- (void)setImage:(UIImage *)image;

// Set placeholder
- (void)setPlaceholder:(UIImage *)placeholder;

// Show loading state
- (void)showLoading:(BOOL)show;

// Show progress
- (void)updateProgress:(CGFloat)progress;

// Handle error
- (void)showError:(NSError *)error;

@optional
// Animation support
- (void)setImage:(UIImage *)image animated:(BOOL)animated;

// Content mode
- (void)setContentMode:(UIViewContentMode)contentMode;

@end
```

#### Framework Adapters

**1. UIKit Adapter**
```objc
@interface CNIUIKitImageView : UIImageView <CNIImageViewAdapter>

+ (instancetype)imageViewWithURL:(NSURL *)url
                         options:(CNILoadOptions *)options;

@end
```

**2. SwiftUI Adapter**
```swift
struct CNIImageView: View {
    let url: URL
    let options: CNILoadOptions

    var body: some View {
        // SwiftUI implementation
    }
}
```

**3. ComponentKit Adapter**
```objc
@interface CNIComponentKitView : CKCompositeComponent

+ (instancetype)newWithURL:(NSURL *)url
                   options:(CNILoadOptions *)options
                      size:(CKComponentSize)size;

@end
```

**4. Objective-C Vanilla Adapter**
```objc
@interface CNIObjCImageView : NSObject

- (void)loadImageFromURL:(NSURL *)url
             intoView:(UIImageView *)imageView
              options:(CNILoadOptions *)options;

@end
```

---

## 🗂️ Task 2: File Control System (Configuration Inheritance)

### Design

#### Configuration Hierarchy
```
Global Config (CNIManager)
    ↓
Request Config (Per-request)
    ↓
Runtime Override (Dynamic)
```

#### Implementation

```objc
// Base Configuration Protocol
@protocol CNIConfiguration <NSObject>

@property (nonatomic, assign) CNIResourcePriority cachePriority;
@property (nonatomic, assign) BOOL shouldSaveToStorage;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) NSUInteger maxRetries;
@property (nonatomic, strong, nullable) NSDictionary *headers;
@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, assign) CGFloat maxImageSize;

@end

// Global Configuration (Singleton defaults)
@interface CNIGlobalConfiguration : NSObject <CNIConfiguration>

+ (instancetype)sharedConfiguration;
- (void)setDefaultCachePriority:(CNIResourcePriority)priority;
- (void)setDefaultStorageEnabled:(BOOL)enabled;

@end

// Request Configuration (Per-request overrides)
@interface CNIRequestConfiguration : NSObject <CNIConfiguration>

- (instancetype)initWithBaseConfiguration:(id<CNIConfiguration>)base;
- (void)overrideCachePriority:(CNIResourcePriority)priority;

@end

// Configuration Builder
@interface CNIConfigurationBuilder : NSObject

+ (instancetype)builder;
- (instancetype)withCachePriority:(CNIResourcePriority)priority;
- (instancetype)withStorageEnabled:(BOOL)enabled;
- (instancetype)withTimeout:(NSTimeInterval)timeout;
- (instancetype)withRetries:(NSUInteger)retries;
- (instancetype)withHeaders:(NSDictionary *)headers;
- (id<CNIConfiguration>)build;

@end
```

#### Usage Example
```objc
// Global configuration (set once)
[[CNIGlobalConfiguration sharedConfiguration]
    setDefaultCachePriority:CNIResourcePriorityLow];

// Per-request override
CNIRequestConfiguration *config = [[[CNIConfigurationBuilder builder]
    withCachePriority:CNIResourcePriorityHigh]
    withStorageEnabled:YES]
    build];

[[CNIManager sharedManager]
    requestImageAtURL:url
    configuration:config
    completion:^(UIImage *image) { }];
```

---

## 🌐 Task 3: Network Layer Improvements

### 3.1 Retry Mechanism with Exponential Backoff

```objc
@interface CNIRetryPolicy : NSObject

@property (nonatomic, assign) NSUInteger maxRetries;
@property (nonatomic, assign) NSTimeInterval baseDelay;
@property (nonatomic, assign) CGFloat backoffMultiplier;

+ (instancetype)defaultPolicy;
+ (instancetype)aggressivePolicy;
+ (instancetype)conservativePolicy;

- (NSTimeInterval)delayForAttempt:(NSUInteger)attempt;

@end
```

### 3.2 Request Deduplication

```objc
// Prevent multiple simultaneous requests for same URL
@interface CNIRequestDeduplicator : NSObject

- (BOOL)shouldExecuteRequestForURL:(NSURL *)url;
- (void)addPendingRequest:(NSURL *)url
                   caller:(id)caller
               completion:(CNIImageCompletionBlock)completion;
- (void)notifyCompletion:(NSURL *)url
                   image:(UIImage *)image
                   error:(NSError *)error;

@end
```

### 3.3 Custom Headers & Authentication

```objc
@interface CNINetworkAgent (Headers)

- (void)setDefaultHeaders:(NSDictionary<NSString *, NSString *> *)headers;
- (void)setAuthenticationHandler:(void (^)(NSMutableURLRequest *request))handler;

@end
```

### 3.4 Bandwidth Throttling

```objc
@interface CNIBandwidthThrottler : NSObject

@property (nonatomic, assign) NSUInteger maxBytesPerSecond;

- (void)throttleDownload:(NSURLSessionDownloadTask *)task;

@end
```

### 3.5 Progressive Image Loading

```objc
// Load low-quality first, then high-quality
- (void)requestProgressiveImageAtURL:(NSURL *)url
                   thumbnailCallback:(void (^)(UIImage *thumbnail))thumbnailBlock
                  fullImageCallback:(void (^)(UIImage *fullImage))fullImageBlock;
```

### 3.6 Format Support (WebP, AVIF)

```objc
@interface CNIImageDecoder : NSObject

+ (UIImage *)decodeImage:(NSData *)data format:(NSString *)format;
+ (BOOL)supportsFormat:(NSString *)format;

@end
```

### 3.7 Request Interceptor Pattern

```objc
@protocol CNIRequestInterceptor <NSObject>

- (NSURLRequest *)interceptRequest:(NSURLRequest *)request;
- (void)didCompleteRequest:(NSURLRequest *)request
                  response:(NSURLResponse *)response
                     error:(NSError *)error;

@end
```

### 3.8 Network Reachability

```objc
@interface CNINetworkMonitor : NSObject

@property (nonatomic, readonly) BOOL isReachable;
@property (nonatomic, readonly) BOOL isWiFi;

+ (instancetype)sharedMonitor;
- (void)startMonitoring;
- (void)onReachabilityChange:(void (^)(BOOL reachable))handler;

@end
```

---

## ✅ Good Sides of CNI Library

### Strengths

1. **✅ Layered Architecture**
   - Clear separation: Manager → Cache → Network → Storage
   - Each layer has single responsibility
   - Easy to test and maintain

2. **✅ Two-Tier Caching**
   - High priority cache (persistent)
   - Low priority cache (evictable)
   - Smart memory management

3. **✅ Observer Pattern**
   - Decoupled event notification
   - Multiple observers supported
   - Clean separation of concerns

4. **✅ Priority-Based Downloads**
   - High priority images load first
   - Queue management
   - Prevents UI blocking

5. **✅ Disk Persistence**
   - Storage agent for offline support
   - Configurable per-request
   - Reduces network usage

6. **✅ Progress Tracking**
   - Real-time download progress
   - UI feedback support
   - Better UX

7. **✅ Caller-Based Cancellation**
   - Cancel specific requests
   - Prevents memory leaks
   - Good for scrolling views

8. **✅ Resource Model**
   - Centralized state management
   - MD5 identifier for dedup
   - Last access tracking for LRU

9. **✅ Statistics API**
   - Cache size monitoring
   - Active downloads count
   - Storage size tracking

10. **✅ ComponentKit Integration**
    - Native CK component
    - Proper lifecycle management
    - Good API design

---

## ❌ Bad Sides / Limitations of CNI Library

### Weaknesses & Missing Features

1. **❌ Framework Coupling**
   - **Issue**: Tightly coupled to UIKit/ComponentKit
   - **Impact**: Can't use in SwiftUI or other frameworks
   - **Fix**: Protocol-based adapter (Task 1)

2. **❌ No Retry Mechanism**
   - **Issue**: Failed downloads don't retry
   - **Impact**: Poor UX on flaky networks
   - **Fix**: Exponential backoff retry (Task 3.1)

3. **❌ Request Duplication**
   - **Issue**: Multiple requests for same URL
   - **Impact**: Wasted bandwidth and memory
   - **Fix**: Request deduplication (Task 3.2)

4. **❌ Limited Format Support**
   - **Issue**: Only supports formats UIImage can decode
   - **Impact**: No WebP, AVIF, or modern formats
   - **Fix**: Custom decoder (Task 3.6)

5. **❌ No Configuration Inheritance**
   - **Issue**: Can't override global settings per-request easily
   - **Impact**: Inflexible API, code duplication
   - **Fix**: Configuration system (Task 2)

6. **❌ No Authentication Support**
   - **Issue**: Can't add custom headers or auth tokens
   - **Impact**: Can't use with private CDNs/APIs
   - **Fix**: Header/auth support (Task 3.3)

7. **❌ No Network Monitoring**
   - **Issue**: Doesn't detect network changes
   - **Impact**: Unnecessary failures, poor offline UX
   - **Fix**: Reachability monitor (Task 3.8)

8. **❌ No Bandwidth Control**
   - **Issue**: Can't throttle downloads
   - **Impact**: Cellular data usage concerns
   - **Fix**: Bandwidth throttler (Task 3.4)

9. **❌ No Progressive Loading**
   - **Issue**: Wait for full image before displaying
   - **Impact**: Slow perceived performance
   - **Fix**: Progressive loading (Task 3.5)

10. **❌ No Request Interceptors**
    - **Issue**: Can't modify requests before sending
    - **Impact**: Hard to add logging, analytics, etc.
    - **Fix**: Interceptor pattern (Task 3.7)

11. **❌ Singleton Anti-Pattern**
    - **Issue**: CNIManager uses singleton
    - **Impact**: Hard to test, global state
    - **Fix**: Dependency injection option

12. **❌ Limited Error Handling**
    - **Issue**: Generic NSError, no retry hints
    - **Impact**: Can't distinguish temporary vs permanent failures
    - **Fix**: Custom error types with retry info

13. **❌ No Image Preprocessing**
    - **Issue**: Can't resize/compress before caching
    - **Impact**: Memory waste for large images
    - **Fix**: Add preprocessing pipeline

14. **❌ Storage Management**
    - **Issue**: No automatic storage cleanup
    - **Impact**: Disk space can grow indefinitely
    - **Fix**: LRU disk cache with size limits

15. **❌ No Prefetching API**
    - **Issue**: Can't preload images in background
    - **Impact**: Missed optimization opportunity
    - **Fix**: Add prefetch API

---

## 📊 Priority Ranking

### High Priority (Must Have for Demo)
1. **Protocol-based adapters** (Task 1) - Required for multi-framework demo
2. **Configuration inheritance** (Task 2) - Shows flexibility
3. **Retry mechanism** (Task 3.1) - Better reliability

### Medium Priority (Nice to Have)
4. Request deduplication (Task 3.2)
5. Custom headers/auth (Task 3.3)
6. Network monitoring (Task 3.8)

### Low Priority (Future Enhancements)
7. Progressive loading (Task 3.5)
8. Format support (Task 3.6)
9. Bandwidth throttling (Task 3.4)
10. Request interceptors (Task 3.7)

---

## 🎬 Demo App Structure

### Recommended Screens

1. **Framework Comparison Screen**
   - Split view showing same image in all 4 frameworks
   - Performance metrics side-by-side

2. **Feature Showcase Screen**
   - Priority-based loading demo
   - Progress tracking demo
   - Cache hit/miss visualization
   - Storage persistence demo

3. **Configuration Demo Screen**
   - Global vs per-request config
   - Override examples
   - Builder pattern usage

4. **Network Scenarios Screen**
   - Retry on failure
   - Offline mode
   - Slow network simulation
   - Cellular vs WiFi

5. **Performance Metrics Screen**
   - Cache statistics
   - Network usage
   - Memory usage
   - Storage size

---

## 📝 Next Steps

1. **Review this plan** - Confirm priorities and approach
2. **Start with Task 1** - Protocol-based adapters (required for demo)
3. **Implement Task 2** - Configuration system
4. **Add Task 3.1** - Retry mechanism
5. **Build demo app** - Showcase all features
6. **Create presentation** - Document good/bad points

Ready to start implementation?
