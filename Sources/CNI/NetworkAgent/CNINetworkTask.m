//
//  CNINetworkTask.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNINetworkTask.h>

@implementation CNINetworkTaskCallback
@end

@implementation CNINetworkTask {
    NSMutableArray<CNINetworkTaskCallback *> *_callbacks;
    dispatch_queue_t _isolationQueue;
}

- (instancetype)initWithURL:(NSURL *)URL priority:(CNIResourcePriority)priority {
    if (self = [super init]) {
        _URL = [URL copy];
        _priority = priority;
        _state = CNINetworkTaskStateNew;
        _progress = 0.0;
        _callbacks = [NSMutableArray array];
        _isolationQueue = dispatch_queue_create(
            "com.cni.networktask.isolation",
            DISPATCH_QUEUE_SERIAL
        );
    }
    return self;
}

- (void)addCallbackWithQueue:(dispatch_queue_t)queue
                    progress:(void (^)(CGFloat))progressBlock
                  completion:(void (^)(UIImage *, NSError *))completion
                      caller:(id)caller
{
    dispatch_sync(_isolationQueue, ^{
        CNINetworkTaskCallback *callback = [[CNINetworkTaskCallback alloc] init];
        callback.queue = queue ?: dispatch_get_main_queue();
        callback.progressBlock = progressBlock;
        callback.completion = completion;
        callback.caller = caller;

        [_callbacks addObject:callback];

        if (_state == CNINetworkTaskStateNew) {
            _state = CNINetworkTaskStateDownloading;
        }
    });
}

- (void)removeCallbacksForCaller:(id)caller {
    dispatch_sync(_isolationQueue, ^{
        [_callbacks filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CNINetworkTaskCallback *cb, NSDictionary *bindings) {
            return cb.caller != caller;
        }]];
    });
}

- (NSUInteger)callbackCount {
    __block NSUInteger count = 0;
    dispatch_sync(_isolationQueue, ^{
        count = _callbacks.count;
    });
    return count;
}

- (void)updateProgress:(CGFloat)progress {
    dispatch_sync(_isolationQueue, ^{
        _progress = progress;

        for (CNINetworkTaskCallback *callback in _callbacks) {
            if (callback.progressBlock) {
                dispatch_async(callback.queue, ^{
                    callback.progressBlock(progress);
                });
            }
        }
    });
}

- (void)completeWithImage:(UIImage *)image error:(NSError *)error {
    dispatch_sync(_isolationQueue, ^{
        _state = image ? CNINetworkTaskStateCompleted : CNINetworkTaskStateFailed;

        for (CNINetworkTaskCallback *callback in _callbacks) {
            if (callback.completion) {
                dispatch_async(callback.queue, ^{
                    callback.completion(image, error);
                });
            }
        }

        [_callbacks removeAllObjects];
    });
}

- (void)cancel {
    dispatch_sync(_isolationQueue, ^{
        _state = CNINetworkTaskStateCancelled;

        if (_sessionTask) {
            [_sessionTask cancel];
            _sessionTask = nil;
        }

        [_callbacks removeAllObjects];
    });
}

@end