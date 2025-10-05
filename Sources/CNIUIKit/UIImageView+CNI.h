//
//  UIImageView+CNI.h
//  CNIUIKit
//
//  Convenience category for adding CNI image loading to any UIImageView
//

#import <UIKit/UIKit.h>
#import <CNI/CNI.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Category on UIImageView for convenient CNI image loading

 Adds CNI image loading capabilities to any UIImageView without subclassing.
 Uses associated objects to track loading state.

 Example usage:
 @code
 UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
 [imageView cni_setImageWithURL:[NSURL URLWithString:@"https://example.com/image.jpg"]
                     placeholder:[UIImage imageNamed:@"placeholder"]];
 @endcode
 */
@interface UIImageView (CNI)

/**
 Load image from URL with default settings

 @param URL Image URL to load
 */
- (void)cni_setImageWithURL:(NSURL *)URL;

/**
 Load image from URL with placeholder

 @param URL Image URL to load
 @param placeholder Placeholder image shown while loading or on error
 */
- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(nullable UIImage *)placeholder;

/**
 Load image from URL with full configuration

 @param URL Image URL to load
 @param placeholder Placeholder image shown while loading or on error
 @param priority Cache priority (CNIResourcePriorityHigh or CNIResourcePriorityLow)
 */
- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(nullable UIImage *)placeholder
                   priority:(CNIResourcePriority)priority;

/**
 Load image from URL with progress tracking

 @param URL Image URL to load
 @param placeholder Placeholder image shown while loading or on error
 @param priority Cache priority
 @param progressBlock Progress callback (0.0 to 1.0)
 */
- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(nullable UIImage *)placeholder
                   priority:(CNIResourcePriority)priority
                 onProgress:(nullable void (^)(CGFloat progress))progressBlock;

/**
 Load image from URL with full configuration and completion

 @param URL Image URL to load
 @param placeholder Placeholder image shown while loading or on error
 @param priority Cache priority
 @param shouldSave Whether to save to disk storage
 @param progressBlock Progress callback (0.0 to 1.0)
 @param completionBlock Completion callback with image result
 */
- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(nullable UIImage *)placeholder
                   priority:(CNIResourcePriority)priority
        shouldSaveToStorage:(BOOL)shouldSave
                 onProgress:(nullable void (^)(CGFloat progress))progressBlock
               onCompletion:(nullable void (^)(UIImage * _Nullable image,
                                                NSError * _Nullable error,
                                                BOOL fromCache,
                                                BOOL fromStorage))completionBlock;

/**
 Cancel current image loading for this UIImageView
 */
- (void)cni_cancelImageLoading;

@end

NS_ASSUME_NONNULL_END
