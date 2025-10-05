//
//  CNICacheAgent.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CNICachePriority) {
    CNICachePriorityLow,    // Can be cleared by memory pressure, replaced when out of slots
    CNICachePriorityHigh    // Only cleared by explicit clear/reset, saved to storage when evicted
};

@protocol CNICacheAgentDelegate <NSObject>
@optional
- (void)cacheDidEvictImageForURL:(NSURL *_Nonnull)URL
                        priority:(CNICachePriority)priority;
@end

@interface CNICacheAgent : NSObject

@property (nonatomic, weak, nullable) id<CNICacheAgentDelegate> delegate;

- (instancetype _Nonnull )initWithHighPriorityLimit:(NSUInteger)highLimit
                                   lowPriorityLimit:(NSUInteger)lowLimit;

// Cache operations
- (UIImage * _Nullable)imageForURL:(NSURL *_Nonnull)URL;
- (void)setImage:(UIImage *_Nonnull)image
          forURL:(NSURL *_Nonnull)URL
        priority:(CNICachePriority)priority;

// Important cache (high priority)
- (void)setImportantImage:(UIImage *_Nonnull)image
                   forURL:(NSURL *_Nonnull)URL;
- (void)clearImportantCacheForURL:(NSURL *_Nonnull)URL;

// Check if URL is cached
- (BOOL)containsImageForURL:(NSURL *_Nonnull)URL;

// Clear operations
- (void)clearLowPriorityCache;
- (void)clearAllCache; // Clears both high and low priority
- (void)hardReset; // Complete reset

// Statistics
- (NSUInteger)highPriorityCacheCount;
- (NSUInteger)lowPriorityCacheCount;

@end
