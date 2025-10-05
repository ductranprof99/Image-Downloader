//
//  CNIImageView.h
//  CNIUIKit - UIKit adapter for CNI
//
//  UIImageView subclass with built-in CNI image loading
//

#import <UIKit/UIKit.h>
#import <CNI/CNI.h>

NS_ASSUME_NONNULL_BEGIN

/**
 UIImageView subclass with built-in CNI image loading support

 Features:
 - Automatic image loading from URL
 - Placeholder support
 - Progress tracking
 - Cache priority control
 - Disk storage configuration
 - Automatic request cancellation on reuse/dealloc

 Example usage:
 @code
 CNIImageView *imageView = [[CNIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
 imageView.placeholderImage = [UIImage imageNamed:@"placeholder"];
 imageView.priority = CNIResourcePriorityHigh;
 [imageView loadImageFromURL:[NSURL URLWithString:@"https://example.com/image.jpg"]];
 @endcode
 */
@interface CNIImageView : UIImageView

#pragma mark - Configuration Properties

/** Placeholder image shown while loading or on error */
@property (nonatomic, strong, nullable) UIImage *placeholderImage;

/** Current image URL being loaded */
@property (nonatomic, copy, nullable, readonly) NSURL *imageURL;

/** Cache priority (default: CNIResourcePriorityLow) */
@property (nonatomic, assign) CNIResourcePriority priority;

/** Whether to save downloaded image to disk storage (default: YES) */
@property (nonatomic, assign) BOOL shouldSaveToStorage;

/** Whether image is currently loading */
@property (nonatomic, assign, readonly) BOOL isLoading;

#pragma mark - Callbacks

/** Progress callback - reports download progress (0.0 to 1.0) */
@property (nonatomic, copy, nullable) void (^onProgress)(CGFloat progress);

/** Completion callback - called when image loads or fails */
@property (nonatomic, copy, nullable) void (^onCompletion)(UIImage * _Nullable image,
                                                             NSError * _Nullable error,
                                                             BOOL fromCache,
                                                             BOOL fromStorage);

#pragma mark - Loading Methods

/**
 Load image from URL with current configuration

 @param URL Image URL to load
 */
- (void)loadImageFromURL:(NSURL *)URL;

/**
 Load image from URL with placeholder

 @param URL Image URL to load
 @param placeholder Placeholder image to show while loading
 */
- (void)loadImageFromURL:(NSURL *)URL
             placeholder:(nullable UIImage *)placeholder;

/**
 Load image from URL with full configuration

 @param URL Image URL to load
 @param placeholder Placeholder image to show while loading
 @param priority Cache priority
 @param shouldSave Whether to save to disk storage
 */
- (void)loadImageFromURL:(NSURL *)URL
             placeholder:(nullable UIImage *)placeholder
                priority:(CNIResourcePriority)priority
     shouldSaveToStorage:(BOOL)shouldSave;

/**
 Cancel current image loading request
 */
- (void)cancelLoading;

@end

NS_ASSUME_NONNULL_END
