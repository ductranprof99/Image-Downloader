//
//  CNINetworkQueue.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNINetworkQueue.h>

@implementation CNINetworkQueue {
    NSMutableArray<CNINetworkTask *> *_highPriorityQueue;
    NSMutableArray<CNINetworkTask *> *_lowPriorityQueue;
    NSMutableDictionary<NSString *, CNINetworkTask *> *_tasksByURL; // URL string -> task
    dispatch_queue_t _isolationQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        _highPriorityQueue = [NSMutableArray array];
        _lowPriorityQueue = [NSMutableArray array];
        _tasksByURL = [NSMutableDictionary dictionary];
        _isolationQueue = dispatch_queue_create(
            "com.cni.networkqueue.isolation",
            DISPATCH_QUEUE_SERIAL
        );
    }
    return self;
}

- (void)enqueueTask:(CNINetworkTask *)task {
    if (!task) return;

    dispatch_sync(_isolationQueue, ^{
        // Check for duplicate URL
        NSString *urlKey = task.URL.absoluteString;
        if (_tasksByURL[urlKey]) {
            return; // Task already exists
        }

        // Add to appropriate priority queue
        if (task.priority == CNIResourcePriorityHigh) {
            [_highPriorityQueue addObject:task];
        } else {
            [_lowPriorityQueue addObject:task];
        }

        _tasksByURL[urlKey] = task;
    });
}

- (CNINetworkTask *)dequeueTask {
    __block CNINetworkTask *task = nil;

    dispatch_sync(_isolationQueue, ^{
        // High priority first
        if (_highPriorityQueue.count > 0) {
            task = _highPriorityQueue.firstObject;
            [_highPriorityQueue removeObjectAtIndex:0];
        } else if (_lowPriorityQueue.count > 0) {
            task = _lowPriorityQueue.firstObject;
            [_lowPriorityQueue removeObjectAtIndex:0];
        }

        if (task) {
            [_tasksByURL removeObjectForKey:task.URL.absoluteString];
        }
    });

    return task;
}

- (CNINetworkTask *)peekNextTask {
    __block CNINetworkTask *task = nil;

    dispatch_sync(_isolationQueue, ^{
        if (_highPriorityQueue.count > 0) {
            task = _highPriorityQueue.firstObject;
        } else if (_lowPriorityQueue.count > 0) {
            task = _lowPriorityQueue.firstObject;
        }
    });

    return task;
}

- (CNINetworkTask *)taskForURL:(NSURL *)URL {
    if (!URL) return nil;

    __block CNINetworkTask *task = nil;

    dispatch_sync(_isolationQueue, ^{
        task = _tasksByURL[URL.absoluteString];
    });

    return task;
}

- (void)removeTask:(CNINetworkTask *)task {
    if (!task) return;

    dispatch_sync(_isolationQueue, ^{
        [_highPriorityQueue removeObject:task];
        [_lowPriorityQueue removeObject:task];
        [_tasksByURL removeObjectForKey:task.URL.absoluteString];
    });
}

- (BOOL)isEmpty {
    __block BOOL empty = YES;

    dispatch_sync(_isolationQueue, ^{
        empty = (_highPriorityQueue.count == 0 && _lowPriorityQueue.count == 0);
    });

    return empty;
}

- (NSUInteger)highPriorityCount {
    __block NSUInteger count = 0;

    dispatch_sync(_isolationQueue, ^{
        count = _highPriorityQueue.count;
    });

    return count;
}

- (NSUInteger)lowPriorityCount {
    __block NSUInteger count = 0;

    dispatch_sync(_isolationQueue, ^{
        count = _lowPriorityQueue.count;
    });

    return count;
}

- (NSUInteger)totalCount {
    __block NSUInteger count = 0;

    dispatch_sync(_isolationQueue, ^{
        count = _highPriorityQueue.count + _lowPriorityQueue.count;
    });

    return count;
}

- (void)clearAllTasks {
    dispatch_sync(_isolationQueue, ^{
        [_highPriorityQueue removeAllObjects];
        [_lowPriorityQueue removeAllObjects];
        [_tasksByURL removeAllObjects];
    });
}

@end