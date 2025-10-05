//
//  CNIObserver.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNIObserver.h>

@implementation CNIObserverManager {
    NSHashTable<id<CNIObserver>> *_observers;
    dispatch_queue_t _observerQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        _observers = [NSHashTable weakObjectsHashTable];
        _observerQueue = dispatch_queue_create(
            "com.cni.observer.queue",
            DISPATCH_QUEUE_SERIAL
        );
    }
    return self;
}

- (void)addObserver:(id<CNIObserver>)observer {
    if (!observer) return;

    dispatch_sync(_observerQueue, ^{
        [_observers addObject:observer];
    });
}

- (void)removeObserver:(id<CNIObserver>)observer {
    if (!observer) return;

    dispatch_sync(_observerQueue, ^{
        [_observers removeObject:observer];
    });
}

- (void)notifyImageDidLoad:(NSURL *)URL fromCache:(BOOL)fromCache fromStorage:(BOOL)fromStorage {
    dispatch_async(_observerQueue, ^{
        for (id<CNIObserver> observer in _observers) {
            if ([observer respondsToSelector:@selector(imageDidLoadForURL:fromCache:fromStorage:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer imageDidLoadForURL:URL fromCache:fromCache fromStorage:fromStorage];
                });
            }
        }
    });
}

- (void)notifyImageDidFail:(NSURL *)URL error:(NSError *)error {
    dispatch_async(_observerQueue, ^{
        for (id<CNIObserver> observer in _observers) {
            if ([observer respondsToSelector:@selector(imageDidFailForURL:error:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer imageDidFailForURL:URL error:error];
                });
            }
        }
    });
}

- (void)notifyDownloadProgress:(NSURL *)URL progress:(CGFloat)progress {
    dispatch_async(_observerQueue, ^{
        for (id<CNIObserver> observer in _observers) {
            if ([observer respondsToSelector:@selector(imageDownloadProgress:progress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer imageDownloadProgress:URL progress:progress];
                });
            }
        }
    });
}

- (void)notifyWillStartDownloading:(NSURL *)URL {
    dispatch_async(_observerQueue, ^{
        for (id<CNIObserver> observer in _observers) {
            if ([observer respondsToSelector:@selector(imageWillStartDownloadingForURL:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer imageWillStartDownloadingForURL:URL];
                });
            }
        }
    });
}

@end