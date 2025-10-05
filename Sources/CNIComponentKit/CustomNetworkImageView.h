//
//  CustomNetworkImageView.h
//  CKTest
//
//  Created by ductd on 24/9/25.
//

#import <ComponentKit/ComponentKit.h>
#import <CNI/CNIManager.h>

typedef NS_ENUM(NSInteger, CustomImageMaskType) {
    CustomImageMaskTypeNone,
    CustomImageMaskTypeCircle,
    CustomImageMaskTypeEllipse,
    CustomImageMaskTypeRounded
};

/**
 Configuration structure for CustomNetworkImageView
 Provides full control over image loading, caching, and display
 */
struct CustomNetworkImageViewOptions {
    /** Placeholder image shown while loading or on error */
    UIImage *placeholder = nil;

    /** Crop rectangle in unit coordinate space (0-1) */
    CGRect cropRect = CGRectZero;

    /** Mask type for the image view */
    CustomImageMaskType maskType = CustomImageMaskTypeNone;

    /** Corner radius (only used with CustomImageMaskTypeRounded) */
    CGFloat cornerRadius = 0.0f;

    /** Cache priority - controls memory cache behavior */
    CNIResourcePriority cachePriority = CNIResourcePriorityLow;

    /** Whether to save downloaded image to disk storage */
    BOOL shouldSaveToStorage = YES;

    /** Whether to show visual progress overlay (default: NO) */
    BOOL progressOverlay = NO;

    /** Progress overlay background color (default: semi-transparent black) */
    UIColor *progressBackgroundColor = nil;

    /** Progress overlay indicator color (default: white) */
    UIColor *progressIndicatorColor = nil;

    /** Progress callback - reports download progress (0.0 to 1.0) */
    void (^onProgress)(CGFloat progress) = nil;

    /** Completion callback - called when image loads or fails */
    void (^onCompletion)(UIImage *image, NSError *error, BOOL fromCache) = nil;
};

/**
 Advanced network image component with full CNI integration

 Features:
 - Full cache control (high/low priority)
 - Progress tracking
 - Disk storage support
 - Multiple mask types (circle, ellipse, rounded)
 - Crop support
 */
@interface CustomNetworkImageView : CKCompositeComponent

/**
 Primary initializer with full configuration

 @param urlString Image URL
 @param size Component size
 @param options Configuration options (see CustomNetworkImageViewOptions)
 @param attributes View attributes for UIImageView
 */
+ (instancetype)newWithURL:(NSString *)urlString
                      size:(const CKComponentSize &)size
                   options:(const CustomNetworkImageViewOptions &)options
                attributes:(const CKViewComponentAttributeValueMap &)attributes;

/**
 Convenience: Basic image with placeholder
 */
+ (instancetype)newWithURL:(NSString *)urlString
               placeholder:(UIImage *)placeholder
                      size:(const CKComponentSize &)size
                attributes:(const CKViewComponentAttributeValueMap &)attributes;

/**
 Convenience: Image with mask type
 */
+ (instancetype)newWithURL:(NSString *)urlString
               placeholder:(UIImage *)placeholder
                      size:(const CKComponentSize &)size
                  maskType:(CustomImageMaskType)maskType
                    radius:(CGFloat)cornerRadius
                attributes:(const CKViewComponentAttributeValueMap &)attributes;

/**
 Convenience: High priority cached image with progress
 */
+ (instancetype)newWithURL:(NSString *)urlString
               placeholder:(UIImage *)placeholder
                      size:(const CKComponentSize &)size
             cachePriority:(CNIResourcePriority)priority
                onProgress:(void (^)(CGFloat progress))progressBlock
                attributes:(const CKViewComponentAttributeValueMap &)attributes;

@end
