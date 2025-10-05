//
//  ComponentImageDownloader.m
//  CKTest
//
//  Created by ductd on 29/9/25.
//

#import "ComponentImageDownloader.h"
#import <CNI/CNIManager.h>

@implementation ComponentImageDownloader {
    NSMutableDictionary<NSString *, NSURL *> *_downloadTokens;
    CNIResourcePriority _priority;
    BOOL _shouldSaveToStorage;
    void (^_userProgressBlock)(CGFloat progress);
    void (^_userCompletionBlock)(UIImage *image, NSError *error, BOOL fromCache);
}

#pragma mark - Factory Methods

+ (instancetype)downloaderWithPriority:(CNIResourcePriority)priority
                   shouldSaveToStorage:(BOOL)shouldSave
                            onProgress:(void (^)(CGFloat))progressBlock
                          onCompletion:(void (^)(UIImage *, NSError *, BOOL))completionBlock
{
    ComponentImageDownloader *downloader = [[self alloc] init];
    downloader->_priority = priority;
    downloader->_shouldSaveToStorage = shouldSave;
    downloader->_userProgressBlock = [progressBlock copy];
    downloader->_userCompletionBlock = [completionBlock copy];
    return downloader;
}

+ (instancetype)downloader {
    return [self downloaderWithPriority:CNIResourcePriorityLow
                    shouldSaveToStorage:YES
                             onProgress:nil
                           onCompletion:nil];
}

+ (instancetype)downloaderWithPriority:(CNIResourcePriority)priority {
    return [self downloaderWithPriority:priority
                    shouldSaveToStorage:YES
                             onProgress:nil
                           onCompletion:nil];
}

+ (instancetype)downloaderWithProgressBlock:(void (^)(CGFloat))progressBlock {
    return [self downloaderWithPriority:CNIResourcePriorityLow
                    shouldSaveToStorage:YES
                             onProgress:progressBlock
                           onCompletion:nil];
}

#pragma mark - Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        _downloadTokens = [NSMutableDictionary dictionary];
        _priority = CNIResourcePriorityLow;
        _shouldSaveToStorage = YES;
    }
    return self;
}

#pragma mark - CKNetworkImageDownloading Protocol

- (id)downloadImageWithURL:(NSURL *)URL
                    caller:(id)caller
             callbackQueue:(dispatch_queue_t)callbackQueue
     downloadProgressBlock:(void (^)(CGFloat))downloadProgressBlock
                completion:(void (^)(CGImageRef, NSError *))completion
{
    if (!URL) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"ComponentImageDownloader"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
            dispatch_async(callbackQueue ?: dispatch_get_main_queue(), ^{
                completion(NULL, error);
            });
        }
        return nil;
    }

    // Generate unique token for this download
    NSString *token = [self _generateTokenForURL:URL];
    @synchronized(_downloadTokens) {
        _downloadTokens[token] = URL;
    }

    // Combine CKNetworkImageComponent's progress with user's progress block
    void (^combinedProgressBlock)(CGFloat) = ^(CGFloat progress) {
        dispatch_queue_t queue = callbackQueue ?: dispatch_get_main_queue();

        // Call CKNetworkImageComponent's progress block
        if (downloadProgressBlock) {
            dispatch_async(queue, ^{
                downloadProgressBlock(progress);
            });
        }

        // Call user's custom progress block
        if (self->_userProgressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_userProgressBlock(progress);
            });
        }
    };

    // Request image from CNIManager with configured settings
    [[CNIManager sharedManager] requestImageAtURL:URL
                                         priority:_priority
                              shouldSaveToStorage:_shouldSaveToStorage
                                         progress:combinedProgressBlock
                                       completion:^(UIImage *image, NSError *error, BOOL fromCache, BOOL fromStorage) {
        dispatch_queue_t queue = callbackQueue ?: dispatch_get_main_queue();

        // Call CKNetworkImageComponent's completion block
        if (completion) {
            CGImageRef cgImage = image ? CGImageRetain(image.CGImage) : NULL;
            dispatch_async(queue, ^{
                completion(cgImage, error);
                if (cgImage) {
                    CGImageRelease(cgImage);
                }
            });
        }

        // Call user's custom completion block on main queue
        if (self->_userCompletionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_userCompletionBlock(image, error, fromCache || fromStorage);
            });
        }

        // Clean up token
        @synchronized(self->_downloadTokens) {
            [self->_downloadTokens removeObjectForKey:token];
        }
    }
                                           caller:caller];

    return token;
}

- (void)cancelImageDownload:(id)download {
    if (!download) {
        return;
    }

    NSString *token = (NSString *)download;
    NSURL *url = nil;

    @synchronized(_downloadTokens) {
        url = _downloadTokens[token];
        if (url) {
            [_downloadTokens removeObjectForKey:token];
        }
    }

    if (url) {
        [[CNIManager sharedManager] cancelRequestForURL:url caller:self];
    }
}

#pragma mark - Private Helpers

- (NSString *)_generateTokenForURL:(NSURL *)URL {
    // Use timestamp + random for better uniqueness
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%@_%.0f_%u",
            URL.absoluteString,
            timestamp * 1000,
            arc4random_uniform(10000)];
}

@end
