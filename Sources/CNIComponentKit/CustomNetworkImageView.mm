//
//  CustomNetworkImageView.m
//  CKTest
//
//  Created by ductd on 24/9/25.
//

#import <CNIComponentKit/CustomNetworkImageView.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ComponentImageDownloader.h"

@implementation CustomNetworkImageView

#pragma mark - Primary Initializer

+ (instancetype)newWithURL:(NSString *)urlString
                      size:(const CKComponentSize &)size
                   options:(const CustomNetworkImageViewOptions &)options
                attributes:(const CKViewComponentAttributeValueMap &)attributes
{
    NSURL *url = [NSURL URLWithString:urlString];

    // Apply mask attributes if needed
    CKViewComponentAttributeValueMap finalAttrs = [
        self
        _applyMaskType:options.maskType
        cornerRadius:options.cornerRadius
        toAttributes:attributes
    ];

    // Create simple downloader
    ComponentImageDownloader *downloader = [
        ComponentImageDownloader
        downloaderWithPriority:options.cachePriority
        shouldSaveToStorage:options.shouldSaveToStorage
        onProgress:options.onProgress
        onCompletion:options.onCompletion
    ];

    // Configure CKNetworkImageComponent options
    CKNetworkImageComponentOptions ckOptions;
    ckOptions.defaultImage = options.placeholder;
    ckOptions.cropRect = options.cropRect;

    CKComponent *imageComponent = [
        CKNetworkImageComponent
        newWithURL:url
        imageDownloader:downloader
        size:size
        options:ckOptions
        attributes:finalAttrs
    ];

    return [super newWithComponent:imageComponent];
}

#pragma mark - Convenience Initializers

/// Totally lazy init with no cache hit
+ (instancetype)newWithURL:(NSString *)urlString
               placeholder:(UIImage *)placeholder
                      size:(const CKComponentSize &)size
                attributes:(const CKViewComponentAttributeValueMap &)attributes
{
    CustomNetworkImageViewOptions options;
    options.placeholder = placeholder;
    options.cachePriority = CNIResourcePriorityLow;
    options.shouldSaveToStorage = NO;

    return [self newWithURL:urlString
                       size:size
                    options:options
                 attributes:attributes];
}

/// Totally lazy init with no cache hit, but with custom sizing
+ (instancetype)newWithURL:(NSString *)urlString
               placeholder:(UIImage *)placeholder
                      size:(const CKComponentSize &)size
                  maskType:(CustomImageMaskType)maskType
                    radius:(CGFloat)cornerRadius
                attributes:(const CKViewComponentAttributeValueMap &)attributes
{
    CustomNetworkImageViewOptions options;
    options.placeholder = placeholder;
    options.maskType = maskType;
    options.cornerRadius = cornerRadius;
    options.cachePriority = CNIResourcePriorityLow;
    options.shouldSaveToStorage = YES;

    return [self newWithURL:urlString
                       size:size
                    options:options
                 attributes:attributes];
}

+ (instancetype)newWithURL:(NSString *)urlString
               placeholder:(UIImage *)placeholder
                      size:(const CKComponentSize &)size
             cachePriority:(CNIResourcePriority)priority
                onProgress:(void (^)(CGFloat))progressBlock
                attributes:(const CKViewComponentAttributeValueMap &)attributes
{
    CustomNetworkImageViewOptions options;
    options.placeholder = placeholder;
    options.cachePriority = priority;
    options.shouldSaveToStorage = YES;
    options.onProgress = progressBlock;

    return [self newWithURL:urlString
                       size:size
                    options:options
                 attributes:attributes];
}

#pragma mark - Private Helpers

+ (CKViewComponentAttributeValueMap)_applyMaskType:(CustomImageMaskType)maskType
                                      cornerRadius:(CGFloat)cornerRadius
                                      toAttributes:(const CKViewComponentAttributeValueMap &)attributes
{
    CKViewComponentAttributeValueMap maskedAttrs = attributes;

    switch (maskType) {
        case CustomImageMaskTypeCircle: {
            const CKComponentViewAttribute kCircleMask("custom.circleMask", ^(UIView *view, id value){
                view.layer.masksToBounds = YES;
                CGFloat r = MIN(view.bounds.size.width, view.bounds.size.height) * 0.5f;
                view.layer.cornerRadius = r;
                view.layer.mask = nil; // Ensure we don't keep a shape mask from reuse
            });
            maskedAttrs.insert({kCircleMask, (id)kCFBooleanTrue});
            break;
        }

        case CustomImageMaskTypeEllipse: {
            const CKComponentViewAttribute kEllipseMask("custom.ellipseMask", ^(UIView *view, id value){
                view.clipsToBounds = YES;
                CAShapeLayer *mask = [CAShapeLayer layer];
                mask.path = [UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath;
                view.layer.mask = mask;
            });
            maskedAttrs.insert({kEllipseMask, (id)kCFBooleanTrue});
            break;
        }

        case CustomImageMaskTypeRounded: {
            const CKComponentViewAttribute kRoundedMask("custom.roundedMask.variable", ^(UIView *view, id value){
                view.layer.masksToBounds = YES;
                view.layer.cornerRadius = cornerRadius;
                view.layer.mask = nil; // Clear any previous ellipse mask
            });
            maskedAttrs.insert({kRoundedMask, (id)kCFBooleanTrue});
            break;
        }

        case CustomImageMaskTypeNone:
        default:
            break;
    }

    return maskedAttrs;
}

@end
