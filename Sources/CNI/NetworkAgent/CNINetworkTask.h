//
//  CNINetworkTask.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CNI/CNIResourceModel.h>

typedef NS_ENUM(NSInteger, CNINetworkTaskState) {
    CNINetworkTaskStateNew,
    CNINetworkTaskStateDownloading,
    CNINetworkTaskStateCompleted,
    CNINetworkTaskStateFailed,
    CNINetworkTaskStateCancelled
};

// Callback for task progress and completion
@interface CNINetworkTaskCallback : NSObject
@property (nonatomic, strong) dispatch_queue_t _Nonnull queue;
@property (nonatomic, copy, nullable) void (^progressBlock)(CGFloat progress);
@property (nonatomic, copy, nullable) void (^completion)(UIImage * _Nullable image, NSError * _Nullable error);
@property (nonatomic, weak, nullable) id caller;
@end

@interface CNINetworkTask : NSObject

@property (nonatomic, readonly) NSURL * _Nonnull URL;
@property (nonatomic, readonly) CNIResourcePriority priority;
@property (nonatomic, readonly) CNINetworkTaskState state;
@property (nonatomic, readonly) CGFloat progress;
@property (nonatomic, readonly) NSUInteger callbackCount;
@property (nonatomic, strong, nullable) NSURLSessionDataTask *sessionTask;

- (instancetype _Nonnull )initWithURL:(NSURL *_Nonnull)URL
                             priority:(CNIResourcePriority)priority;

// Callback management
- (void)addCallbackWithQueue:(dispatch_queue_t _Nullable)queue
                    progress:(void (^ _Nullable)(CGFloat))progressBlock
                  completion:(void (^ _Nullable)(UIImage * _Nullable, NSError * _Nullable))completion
                      caller:(id _Nullable)caller;

- (void)removeCallbacksForCaller:(id _Nullable)caller;

// Execution
- (void)updateProgress:(CGFloat)progress;
- (void)completeWithImage:(UIImage * _Nullable)image error:(NSError * _Nullable)error;
- (void)cancel;

@end
