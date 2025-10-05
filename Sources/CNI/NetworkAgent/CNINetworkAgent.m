//
//  CNINetworkAgent.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNINetworkAgent.h>
#import <CNI/CNINetworkQueue.h>

@interface CNINetworkAgent () <NSURLSessionDataDelegate>
@end

@implementation CNINetworkAgent {
    CNINetworkQueue *_queue;
    NSURLSession *_session;
    NSMutableDictionary<NSString *, CNINetworkTask *> *_activeDownloads; // URL string -> task
    NSMutableDictionary<NSString *, CNINetworkTask *> *_allTasks; // URL string -> task (includes queued + active)
    NSMutableDictionary<NSNumber *, CNINetworkTask *> *_taskMap; // sessionTask.taskIdentifier -> CNINetworkTask
    NSMutableDictionary<NSNumber *, NSMutableData *> *_dataMap; // sessionTask.taskIdentifier -> received data
    NSMutableDictionary<NSNumber *, NSNumber *> *_expectedLengthMap; // sessionTask.taskIdentifier -> expected content length
    dispatch_queue_t _isolationQueue;
}

- (instancetype)init {
    return [self initWithMaxConcurrentDownloads:4];
}

- (instancetype)initWithMaxConcurrentDownloads:(NSUInteger)maxConcurrent {
    if (self = [super init]) {
        _maxConcurrentDownloads = maxConcurrent;
        _queue = [[CNINetworkQueue alloc] init];
        _activeDownloads = [NSMutableDictionary dictionary];
        _allTasks = [NSMutableDictionary dictionary];
        _taskMap = [NSMutableDictionary dictionary];
        _dataMap = [NSMutableDictionary dictionary];
        _expectedLengthMap = [NSMutableDictionary dictionary];
        _isolationQueue = dispatch_queue_create(
            "com.cni.networkagent.isolation",
            DISPATCH_QUEUE_SERIAL
        );

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = maxConcurrent;
        _session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:self
                                            delegateQueue:nil];
    }
    return self;
}

- (void)downloadResourceAtURL:(NSURL *)URL
                     priority:(CNIResourcePriority)priority
                     progress:(void (^)(CGFloat))progressBlock
                   completion:(void (^)(UIImage *, NSError *))completion
                       caller:(id)caller
{
    if (!URL) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"CNINetworkAgent"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
            completion(nil, error);
        }
        return;
    }

    dispatch_async(_isolationQueue, ^{
        NSString *urlKey = URL.absoluteString;
        CNINetworkTask *existingTask = _allTasks[urlKey];

        if (existingTask) {
            // Task already exists, just add callback
            [existingTask addCallbackWithQueue:dispatch_get_main_queue()
                                     progress:progressBlock
                                   completion:completion
                                       caller:caller];
        } else {
            // Create new task
            CNINetworkTask *task = [[CNINetworkTask alloc] initWithURL:URL priority:priority];
            [task addCallbackWithQueue:dispatch_get_main_queue()
                             progress:progressBlock
                           completion:completion
                               caller:caller];

            _allTasks[urlKey] = task;
            [_queue enqueueTask:task];

            // Try to start downloads
            [self _processQueue];
        }
    });
}

- (void)cancelDownloadForURL:(NSURL *)URL caller:(id)caller {
    if (!URL) return;

    dispatch_async(_isolationQueue, ^{
        NSString *urlKey = URL.absoluteString;
        CNINetworkTask *task = _allTasks[urlKey];

        if (task) {
            [task removeCallbacksForCaller:caller];

            // If no more callbacks, cancel the task
            if (task.callbackCount == 0) {
                [task cancel];
                [_activeDownloads removeObjectForKey:urlKey];
                [_queue removeTask:task];
                [_allTasks removeObjectForKey:urlKey];

                // Process queue to start next task
                [self _processQueue];
            }
        }
    });
}

- (void)cancelAllDownloadsForURL:(NSURL *)URL {
    if (!URL) return;

    dispatch_async(_isolationQueue, ^{
        NSString *urlKey = URL.absoluteString;
        CNINetworkTask *task = _allTasks[urlKey];

        if (task) {
            [task cancel];
            [_activeDownloads removeObjectForKey:urlKey];
            [_queue removeTask:task];
            [_allTasks removeObjectForKey:urlKey];

            // Process queue to start next task
            [self _processQueue];
        }
    });
}

- (NSUInteger)activeDownloadCount {
    __block NSUInteger count = 0;
    dispatch_sync(_isolationQueue, ^{
        count = _activeDownloads.count;
    });
    return count;
}

- (NSUInteger)queuedTaskCount {
    return [_queue totalCount];
}

#pragma mark - Private

- (void)_processQueue {
    // Must be called on _isolationQueue
    while (_activeDownloads.count < _maxConcurrentDownloads && ![_queue isEmpty]) {
        CNINetworkTask *task = [_queue dequeueTask];
        if (task) {
            [self _startDownloadTask:task];
        }
    }
}

- (void)_startDownloadTask:(CNINetworkTask *)task {
    // Must be called on _isolationQueue
    NSString *urlKey = task.URL.absoluteString;
    _activeDownloads[urlKey] = task;

    // Create data task (will use delegate methods for progress)
    NSURLSessionDataTask *sessionTask = [_session dataTaskWithURL:task.URL];

    // Map session task to our CNI task for delegate callbacks
    NSNumber *taskID = @(sessionTask.taskIdentifier);
    _taskMap[taskID] = task;
    _dataMap[taskID] = [NSMutableData data];

    task.sessionTask = sessionTask;
    [sessionTask resume];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    dispatch_async(_isolationQueue, ^{
        NSNumber *taskID = @(dataTask.taskIdentifier);

        // Store expected content length
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            _expectedLengthMap[taskID] = @(httpResponse.expectedContentLength);
        }

        // Reset data buffer
        _dataMap[taskID] = [NSMutableData data];
    });

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    dispatch_async(_isolationQueue, ^{
        NSNumber *taskID = @(dataTask.taskIdentifier);
        CNINetworkTask *task = _taskMap[taskID];
        NSMutableData *accumulatedData = _dataMap[taskID];

        if (!task || !accumulatedData) return;

        // Accumulate data
        [accumulatedData appendData:data];

        // Calculate progress
        NSNumber *expectedLength = _expectedLengthMap[taskID];
        if (expectedLength && expectedLength.longLongValue > 0) {
            CGFloat progress = (CGFloat)accumulatedData.length / expectedLength.doubleValue;
            progress = MIN(progress, 1.0); // Cap at 1.0

            // Update task progress - this will notify all callbacks
            [task updateProgress:progress];
        }
    });
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)sessionTask
didCompleteWithError:(NSError *)error
{
    dispatch_async(_isolationQueue, ^{
        NSNumber *taskID = @(sessionTask.taskIdentifier);
        CNINetworkTask *task = _taskMap[taskID];
        NSMutableData *data = _dataMap[taskID];

        if (!task) return;

        NSString *urlKey = task.URL.absoluteString;

        UIImage *image = nil;
        NSError *finalError = error;

        if (data && !error) {
            image = [UIImage imageWithData:data];
            if (!image) {
                finalError = [NSError errorWithDomain:@"CNINetworkAgent"
                                                 code:-2
                                             userInfo:@{NSLocalizedDescriptionKey: @"Failed to decode image"}];
            }
        }

        // Complete the task - this will notify all callbacks
        [task completeWithImage:image error:finalError];

        // Cleanup
        [_activeDownloads removeObjectForKey:urlKey];
        [_allTasks removeObjectForKey:urlKey];
        [_taskMap removeObjectForKey:taskID];
        [_dataMap removeObjectForKey:taskID];
        [_expectedLengthMap removeObjectForKey:taskID];

        // Start next task in queue
        [self _processQueue];
    });
}

@end
