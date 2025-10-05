//
//  CNIObserver.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>

@protocol CNIObserver <NSObject>
@optional

// Called when image is successfully loaded (from any source: cache, storage, or network)
- (void)imageDidLoadForURL:(NSURL *)URL
                 fromCache:(BOOL)fromCache
               fromStorage:(BOOL)fromStorage;

// Called when image download/load fails
- (void)imageDidFailForURL:(NSURL *)URL
                     error:(NSError *)error;

// Called during download progress
- (void)imageDownloadProgress:(NSURL *)URL
                     progress:(CGFloat)progress;

// Called when image is starting to download
- (void)imageWillStartDownloadingForURL:(NSURL *)URL;

@end

@interface CNIObserverManager : NSObject

- (void)addObserver:(id<CNIObserver>)observer;
- (void)removeObserver:(id<CNIObserver>)observer;

// Notification methods
- (void)notifyImageDidLoad:(NSURL *)URL
                 fromCache:(BOOL)fromCache
               fromStorage:(BOOL)fromStorage;

- (void)notifyImageDidFail:(NSURL *)URL
                     error:(NSError *)error;

- (void)notifyDownloadProgress:(NSURL *)URL
                      progress:(CGFloat)progress;

- (void)notifyWillStartDownloading:(NSURL *)URL;

@end
