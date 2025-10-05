//
//  CNICacheAgent.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNICacheAgent.h>


@interface CNICacheEntry : NSObject
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSDate *lastAccessDate;
@property (nonatomic, assign) CNICachePriority priority;
@end

@implementation CNICacheEntry
@end

@implementation CNICacheAgent {
    NSMutableDictionary<NSString *, CNICacheEntry *> *_cacheData; // URL string -> entry
    NSMutableArray<NSString *> *_highPriorityKeys; // LRU tracking for high priority
    NSMutableArray<NSString *> *_lowPriorityKeys;  // LRU tracking for low priority
    NSUInteger _highPriorityLimit;
    NSUInteger _lowPriorityLimit;
    dispatch_queue_t _isolationQueue;
}

- (instancetype)init {
    return [self initWithHighPriorityLimit:50 lowPriorityLimit:100];
}

- (instancetype)initWithHighPriorityLimit:(NSUInteger)highLimit
                          lowPriorityLimit:(NSUInteger)lowLimit
{
    if (self = [super init]) {
        _highPriorityLimit = highLimit;
        _lowPriorityLimit = lowLimit;
        _cacheData = [NSMutableDictionary dictionary];
        _highPriorityKeys = [NSMutableArray array];
        _lowPriorityKeys = [NSMutableArray array];
        _isolationQueue = dispatch_queue_create(
            "com.cni.cacheagent.isolation",
            DISPATCH_QUEUE_SERIAL
        );

        [self _setupMemoryWarningObserver];
    }
    return self;
}

- (UIImage *)imageForURL:(NSURL *)URL {
    if (!URL) return nil;

    __block UIImage *image = nil;

    dispatch_sync(_isolationQueue, ^{
        NSString *urlKey = URL.absoluteString;
        CNICacheEntry *entry = _cacheData[urlKey];

        if (entry) {
            entry.lastAccessDate = [NSDate date];
            image = entry.image;

            // Update LRU: move to end (most recently used)
            if (entry.priority == CNICachePriorityHigh) {
                [_highPriorityKeys removeObject:urlKey];
                [_highPriorityKeys addObject:urlKey];
            } else {
                [_lowPriorityKeys removeObject:urlKey];
                [_lowPriorityKeys addObject:urlKey];
            }
        }
    });

    return image;
}

- (void)setImage:(UIImage *)image forURL:(NSURL *)URL priority:(CNICachePriority)priority {
    if (!image || !URL) return;

    dispatch_sync(_isolationQueue, ^{
        NSString *urlKey = URL.absoluteString;

        // Check if already exists
        CNICacheEntry *existingEntry = _cacheData[urlKey];
        if (existingEntry) {
            // Update existing entry
            existingEntry.image = image;
            existingEntry.lastAccessDate = [NSDate date];

            // Update priority if changed
            if (existingEntry.priority != priority) {
                if (existingEntry.priority == CNICachePriorityHigh) {
                    [_highPriorityKeys removeObject:urlKey];
                } else {
                    [_lowPriorityKeys removeObject:urlKey];
                }

                existingEntry.priority = priority;

                if (priority == CNICachePriorityHigh) {
                    [_highPriorityKeys addObject:urlKey];
                } else {
                    [_lowPriorityKeys addObject:urlKey];
                }
            } else {
                // Just update LRU position
                if (priority == CNICachePriorityHigh) {
                    [_highPriorityKeys removeObject:urlKey];
                    [_highPriorityKeys addObject:urlKey];
                } else {
                    [_lowPriorityKeys removeObject:urlKey];
                    [_lowPriorityKeys addObject:urlKey];
                }
            }
        } else {
            // Create new entry
            CNICacheEntry *entry = [[CNICacheEntry alloc] init];
            entry.image = image;
            entry.URL = URL;
            entry.priority = priority;
            entry.lastAccessDate = [NSDate date];

            _cacheData[urlKey] = entry;

            if (priority == CNICachePriorityHigh) {
                [_highPriorityKeys addObject:urlKey];
                [self _evictHighPriorityCacheIfNeeded];
            } else {
                [_lowPriorityKeys addObject:urlKey];
                [self _evictLowPriorityCacheIfNeeded];
            }
        }
    });
}

- (void)setImportantImage:(UIImage *)image forURL:(NSURL *)URL {
    [self setImage:image forURL:URL priority:CNICachePriorityHigh];
}

- (void)clearImportantCacheForURL:(NSURL *)URL {
    if (!URL) return;

    dispatch_sync(_isolationQueue, ^{
        NSString *urlKey = URL.absoluteString;
        CNICacheEntry *entry = _cacheData[urlKey];

        if (entry && entry.priority == CNICachePriorityHigh) {
            [_cacheData removeObjectForKey:urlKey];
            [_highPriorityKeys removeObject:urlKey];
        }
    });
}

- (BOOL)containsImageForURL:(NSURL *)URL {
    if (!URL) return NO;

    __block BOOL contains = NO;

    dispatch_sync(_isolationQueue, ^{
        contains = (_cacheData[URL.absoluteString] != nil);
    });

    return contains;
}

- (void)clearLowPriorityCache {
    dispatch_sync(_isolationQueue, ^{
        for (NSString *urlKey in _lowPriorityKeys) {
            [_cacheData removeObjectForKey:urlKey];
        }
        [_lowPriorityKeys removeAllObjects];
    });
}

- (void)clearAllCache {
    dispatch_sync(_isolationQueue, ^{
        [_cacheData removeAllObjects];
        [_highPriorityKeys removeAllObjects];
        [_lowPriorityKeys removeAllObjects];
    });
}

- (void)hardReset {
    [self clearAllCache];
}

- (NSUInteger)highPriorityCacheCount {
    __block NSUInteger count = 0;
    dispatch_sync(_isolationQueue, ^{
        count = _highPriorityKeys.count;
    });
    return count;
}

- (NSUInteger)lowPriorityCacheCount {
    __block NSUInteger count = 0;
    dispatch_sync(_isolationQueue, ^{
        count = _lowPriorityKeys.count;
    });
    return count;
}

#pragma mark - Private

- (void)_evictHighPriorityCacheIfNeeded {
    // Must be called on _isolationQueue
    while (_highPriorityKeys.count > _highPriorityLimit) {
        // Evict least recently used (first item)
        NSString *urlKey = _highPriorityKeys.firstObject;
        CNICacheEntry *entry = _cacheData[urlKey];

        if (entry) {
            // Notify delegate for saving to storage
            if (self.delegate && [self.delegate respondsToSelector:@selector(cacheDidEvictImageForURL:priority:)]) {
                NSURL *url = entry.URL;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cacheDidEvictImageForURL:url priority:CNICachePriorityHigh];
                });
            }
        }

        [_cacheData removeObjectForKey:urlKey];
        [_highPriorityKeys removeObjectAtIndex:0];
    }
}

- (void)_evictLowPriorityCacheIfNeeded {
    // Must be called on _isolationQueue
    while (_lowPriorityKeys.count > _lowPriorityLimit) {
        // Evict least recently used (first item)
        NSString *urlKey = _lowPriorityKeys.firstObject;
        [_cacheData removeObjectForKey:urlKey];
        [_lowPriorityKeys removeObjectAtIndex:0];

        // No need to save to storage for low priority
    }
}

- (void)_setupMemoryWarningObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        [self clearLowPriorityCache];
    }];
}

@end
