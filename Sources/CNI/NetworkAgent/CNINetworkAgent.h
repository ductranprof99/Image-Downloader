//
//  CNINetworkAgent.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CNI/CNINetworkTask.h>
#import <CNI/CNIResourceModel.h>

@interface CNINetworkAgent : NSObject

@property (nonatomic, assign) NSUInteger maxConcurrentDownloads; // Default: 4

- (instancetype _Nonnull )initWithMaxConcurrentDownloads:(NSUInteger)maxConcurrent;

// Request download
- (void)downloadResourceAtURL:(NSURL *_Nonnull)URL
                     priority:(CNIResourcePriority)priority
                     progress:(void (^ _Nullable)(CGFloat progress))progressBlock
                   completion:(void (^ _Nullable)(UIImage * _Nullable image, NSError * _Nullable error))completion
                       caller:(id _Nullable)caller;

// Cancel download for specific caller
- (void)cancelDownloadForURL:(NSURL *_Nonnull)URL
                      caller:(id _Nullable )caller;

// Cancel all downloads for URL
- (void)cancelAllDownloadsForURL:(NSURL *_Nonnull)URL;

// Get current download count
- (NSUInteger)activeDownloadCount;

// Queue statistics
- (NSUInteger)queuedTaskCount;

@end
