//
//  CNIManager.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNIManager.h>
#import <CNI/CNICacheAgent.h>
#import <CNI/CNIStorageAgent.h>
#import <CNI/CNINetworkAgent.h>

@interface CNIManager () <CNICacheAgentDelegate>
@end

@implementation CNIManager {
    CNICacheAgent *_cacheAgent;
    CNIStorageAgent *_storageAgent;
    CNINetworkAgent *_networkAgent;
    CNIObserverManager *_observerManager;
    dispatch_queue_t _managerQueue;
}

+ (instancetype)sharedManager {
    static CNIManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CNIManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        // Default configuration
        _cacheAgent = [[CNICacheAgent alloc] initWithHighPriorityLimit:50 lowPriorityLimit:100];
        _cacheAgent.delegate = self;

        _storageAgent = [[CNIStorageAgent alloc] initWithStoragePath:nil];
        _networkAgent = [[CNINetworkAgent alloc] initWithMaxConcurrentDownloads:4];
        _observerManager = [[CNIObserverManager alloc] init];

        _managerQueue = dispatch_queue_create(
            "com.cni.manager.queue",
            DISPATCH_QUEUE_SERIAL
        );
    }
    return self;
}

- (CNIObserverManager *)observerManager {
    return _observerManager;
}

- (void)configureWithMaxConcurrentDownloads:(NSUInteger)maxConcurrent
                         highCachePriority:(NSUInteger)highCacheLimit
                          lowCachePriority:(NSUInteger)lowCacheLimit
                               storagePath:(NSString *)storagePath
{
    _cacheAgent = [[CNICacheAgent alloc] initWithHighPriorityLimit:highCacheLimit
                                                   lowPriorityLimit:lowCacheLimit];
    _cacheAgent.delegate = self;

    _storageAgent = [[CNIStorageAgent alloc] initWithStoragePath:storagePath];
    _networkAgent = [[CNINetworkAgent alloc] initWithMaxConcurrentDownloads:maxConcurrent];
}

#pragma mark - Main API

- (void)requestImageAtURL:(NSURL *)URL
                 priority:(CNIResourcePriority)priority
        shouldSaveToStorage:(BOOL)shouldSave
                 progress:(CNIImageProgressBlock)progressBlock
               completion:(CNIImageCompletionBlock)completion
                   caller:(id)caller
{
    if (!URL) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"CNIManager"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
            completion(nil, error, NO, NO);
        }
        return;
    }

    dispatch_async(_managerQueue, ^{
        // Step 1: Check cache
        UIImage *cachedImage = [_cacheAgent imageForURL:URL];
        if (cachedImage) {
            [_observerManager notifyImageDidLoad:URL fromCache:YES fromStorage:NO];
            // Report instant progress for cached images
            if (progressBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressBlock(1.0);
                });
            }
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(cachedImage, nil, YES, NO);
                });
            }
            return;
        }

        // Step 2: Check storage
        [_storageAgent imageForURL:URL completion:^(UIImage *storageImage) {
            if (storageImage) {
                // Put in cache for fast access next time
                CNICachePriority cachePriority = (priority == CNIResourcePriorityHigh) ? CNICachePriorityHigh : CNICachePriorityLow;
                [_cacheAgent setImage:storageImage forURL:URL priority:cachePriority];

                [_observerManager notifyImageDidLoad:URL fromCache:NO fromStorage:YES];

                // Report instant progress for storage images
                if (progressBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressBlock(1.0);
                    });
                }
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(storageImage, nil, NO, YES);
                    });
                }
            } else {
                // Step 3: Download from network
                [self _downloadImageFromNetworkAtURL:URL
                                           priority:priority
                                  shouldSaveToStorage:shouldSave
                                           progress:progressBlock
                                         completion:completion
                                             caller:caller];
            }
        }];
    });
}

- (void)requestImageAtURL:(NSURL *)URL completion:(CNIImageCompletionBlock)completion {
    [self requestImageAtURL:URL
                   priority:CNIResourcePriorityLow
          shouldSaveToStorage:YES
                   progress:nil
                 completion:completion
                     caller:nil];
}

- (void)forceReloadImageAtURL:(NSURL *)URL
                     priority:(CNIResourcePriority)priority
            shouldSaveToStorage:(BOOL)shouldSave
                     progress:(CNIImageProgressBlock)progressBlock
                   completion:(CNIImageCompletionBlock)completion
                       caller:(id)caller
{
    if (!URL) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"CNIManager"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
            completion(nil, error, NO, NO);
        }
        return;
    }

    // Bypass cache and storage, go directly to network
    [self _downloadImageFromNetworkAtURL:URL
                               priority:priority
                      shouldSaveToStorage:shouldSave
                               progress:progressBlock
                             completion:completion
                                 caller:caller];
}

- (void)cancelRequestForURL:(NSURL *)URL caller:(id)caller {
    [_networkAgent cancelDownloadForURL:URL caller:caller];
}

- (void)cancelAllRequestsForURL:(NSURL *)URL {
    [_networkAgent cancelAllDownloadsForURL:URL];
}

#pragma mark - Cache Management

- (void)clearLowPriorityCache {
    [_cacheAgent clearLowPriorityCache];
}

- (void)clearAllCache {
    [_cacheAgent clearAllCache];
}

- (void)clearStorage:(void (^)(BOOL))completion {
    [_storageAgent clearAllStorage:completion];
}

- (void)hardReset {
    [_cacheAgent hardReset];
    [_storageAgent clearAllStorage:nil];
}

#pragma mark - Observer Management

- (void)addObserver:(id<CNIObserver>)observer {
    [_observerManager addObserver:observer];
}

- (void)removeObserver:(id<CNIObserver>)observer {
    [_observerManager removeObserver:observer];
}

#pragma mark - Statistics

- (NSUInteger)cacheSizeHigh {
    return [_cacheAgent highPriorityCacheCount];
}

- (NSUInteger)cacheSizeLow {
    return [_cacheAgent lowPriorityCacheCount];
}

- (NSUInteger)storageSizeBytes {
    return [_storageAgent currentStorageSize];
}

- (NSUInteger)activeDownloadsCount {
    return [_networkAgent activeDownloadCount];
}

- (NSUInteger)queuedDownloadsCount {
    return [_networkAgent queuedTaskCount];
}

#pragma mark - Private

- (void)_downloadImageFromNetworkAtURL:(NSURL *)URL
                             priority:(CNIResourcePriority)priority
                    shouldSaveToStorage:(BOOL)shouldSave
                             progress:(CNIImageProgressBlock)progressBlock
                           completion:(CNIImageCompletionBlock)completion
                               caller:(id)caller
{
    [_observerManager notifyWillStartDownloading:URL];

    [_networkAgent downloadResourceAtURL:URL
                               priority:priority
                               progress:^(CGFloat progress) {
        // Forward progress
        [_observerManager notifyDownloadProgress:URL progress:progress];
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressBlock(progress);
            });
        }
    }
                             completion:^(UIImage *image, NSError *error) {
        if (image) {
            // Success: update cache
            CNICachePriority cachePriority = (priority == CNIResourcePriorityHigh) ? CNICachePriorityHigh : CNICachePriorityLow;
            [_cacheAgent setImage:image forURL:URL priority:cachePriority];

            // Save to storage if needed
            if (shouldSave) {
                [_storageAgent saveImage:image forURL:URL completion:nil];
            }

            [_observerManager notifyImageDidLoad:URL fromCache:NO fromStorage:NO];

            if (completion) {
                completion(image, nil, NO, NO);
            }
        } else {
            // Failure
            [_observerManager notifyImageDidFail:URL error:error];

            if (completion) {
                completion(nil, error, NO, NO);
            }
        }
    }
                                 caller:caller];
}

#pragma mark - CNICacheAgentDelegate

- (void)cacheDidEvictImageForURL:(NSURL *)URL priority:(CNICachePriority)priority {
    // When high priority cache evicts an image, save it to storage
    if (priority == CNICachePriorityHigh) {
        // Try to get the image from cache one more time before it's fully evicted
        // (This is called before actual removal in some implementations)
        // For now, we'll just note that we should have saved it earlier
        // In production, you might want to retrieve and save here
    }
}

@end
