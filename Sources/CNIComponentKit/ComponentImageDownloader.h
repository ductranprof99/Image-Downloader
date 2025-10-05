//
//  ComponentImageDownloader.h
//  CKTest
//
//  Created by ductd on 29/9/25.
//

#import <ComponentKit/CKNetworkImageDownloading.h>
#import <CNI/CNIManager.h>

/**
 Bridge between CKNetworkImageComponent and CNIManager

 Exposes full CNI capabilities:
 - Cache priority control (high/low)
 - Disk storage configuration
 - Progress tracking
 - Completion callbacks with cache/storage info
 */
@interface ComponentImageDownloader : NSObject <CKNetworkImageDownloading>

/**
 Create downloader with full CNI configuration

 @param priority Cache priority (CNIResourcePriorityHigh or CNIResourcePriorityLow)
 @param shouldSave Whether to save downloaded image to disk storage
 @param progressBlock Progress callback (0.0 to 1.0) - called on main queue
 @param completionBlock Completion callback with cache/storage info - called on main queue
 */
+ (instancetype)downloaderWithPriority:(CNIResourcePriority)priority
                   shouldSaveToStorage:(BOOL)shouldSave
                            onProgress:(void (^)(CGFloat progress))progressBlock
                          onCompletion:(void (^)(UIImage *image, NSError *error, BOOL fromCache))completionBlock;

/**
 Convenience: Create default downloader (low priority, saves to storage)
 */
+ (instancetype)downloader;

/**
 Convenience: Create downloader with priority control
 */
+ (instancetype)downloaderWithPriority:(CNIResourcePriority)priority;

/**
 Convenience: Create downloader with progress tracking
 */
+ (instancetype)downloaderWithProgressBlock:(void (^)(CGFloat progress))progressBlock;

@end
