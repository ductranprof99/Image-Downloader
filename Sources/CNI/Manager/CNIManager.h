//
//  CNIManager.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CNI/CNIObserver.h>
#import <CNI/CNIResourceModel.h>

typedef void (^CNIImageCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, BOOL fromCache, BOOL fromStorage);
typedef void (^CNIImageProgressBlock)(CGFloat progress);

@interface CNIManager : NSObject

@property (nonatomic, readonly) CNIObserverManager * _Nonnull observerManager;

// Singleton
+ (instancetype _Nonnull )sharedManager;

// Configuration
- (void)configureWithMaxConcurrentDownloads:(NSUInteger)maxConcurrent
                          highCachePriority:(NSUInteger)highCacheLimit
                           lowCachePriority:(NSUInteger)lowCacheLimit
                                storagePath:(NSString * _Nullable)storagePath;

// Main API - Request image resource
- (void)requestImageAtURL:(NSURL *_Nonnull)URL
                 priority:(CNIResourcePriority)priority
      shouldSaveToStorage:(BOOL)shouldSave
                 progress:(CNIImageProgressBlock _Nullable)progressBlock
               completion:(CNIImageCompletionBlock _Nullable)completion
                   caller:(id _Nullable)caller;

// Simplified API
- (void)requestImageAtURL:(NSURL *_Nonnull)URL
               completion:(CNIImageCompletionBlock _Nullable)completion;

// Force reload (bypass cache/storage, fetch from network)
- (void)forceReloadImageAtURL:(NSURL *_Nonnull)URL
                     priority:(CNIResourcePriority)priority
          shouldSaveToStorage:(BOOL)shouldSave
                     progress:(CNIImageProgressBlock _Nullable)progressBlock
                   completion:(CNIImageCompletionBlock _Nullable)completion
                       caller:(id _Nullable)caller;

// Cancel requests
- (void)cancelRequestForURL:(NSURL *_Nonnull)URL
                     caller:(id _Nullable )caller;
- (void)cancelAllRequestsForURL:(NSURL *_Nonnull)URL;

// Cache management
- (void)clearLowPriorityCache;
- (void)clearAllCache;
- (void)clearStorage:(void (^ _Nullable)(BOOL success))completion;
- (void)hardReset; // Clear everything

// Observer management
- (void)addObserver:(id<CNIObserver>_Nonnull)observer;
- (void)removeObserver:(id<CNIObserver>_Nonnull)observer;

// Statistics
- (NSUInteger)cacheSizeHigh;
- (NSUInteger)cacheSizeLow;
- (NSUInteger)storageSizeBytes;
- (NSUInteger)activeDownloadsCount;
- (NSUInteger)queuedDownloadsCount;

@end
