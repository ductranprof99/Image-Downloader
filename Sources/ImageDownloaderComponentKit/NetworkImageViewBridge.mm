//
//  NetworkImageViewBridge.mm
//  ImageDownloaderComponentKit
//
//  Objective-C++ bridge implementation for NetworkImageView
//  Handles ComponentKit C++ integration
//

#import "NetworkImageViewBridge.h"
#import <ImageDownloaderComponentKit/ImageDownloaderComponentKit-Swift.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@implementation NetworkImageViewBridge

#pragma mark - Component Creation

+ (CKComponent *)createComponentWithURL:(NSString *)urlString
                                   size:(const CKComponentSize &)size
                                options:(NetworkImageViewOptions *)options
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

    // Create image downloader
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

    // Create the component
    CKComponent *imageComponent = [
        CKNetworkImageComponent
        newWithURL:url
        imageDownloader:downloader
        size:size
        options:ckOptions
        attributes:finalAttrs
    ];

    return [CKCompositeComponent newWithComponent:imageComponent];
}

#pragma mark - Private Helpers

+ (CKViewComponentAttributeValueMap)_applyMaskType:(ImageMaskType)maskType
                                      cornerRadius:(CGFloat)cornerRadius
                                      toAttributes:(const CKViewComponentAttributeValueMap &)attributes
{
    CKViewComponentAttributeValueMap maskedAttrs = attributes;

    switch (maskType) {
        case ImageMaskTypeCircle: {
            const CKComponentViewAttribute kCircleMask("imageview.circleMask", ^(UIView *view, id value){
                view.layer.masksToBounds = YES;
                CGFloat r = MIN(view.bounds.size.width, view.bounds.size.height) * 0.5f;
                view.layer.cornerRadius = r;
                view.layer.mask = nil; // Ensure we don't keep a shape mask from reuse
            });
            maskedAttrs.insert({kCircleMask, (id)kCFBooleanTrue});
            break;
        }

        case ImageMaskTypeEllipse: {
            const CKComponentViewAttribute kEllipseMask("imageview.ellipseMask", ^(UIView *view, id value){
                view.clipsToBounds = YES;
                CAShapeLayer *mask = [CAShapeLayer layer];
                mask.path = [UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath;
                view.layer.mask = mask;
            });
            maskedAttrs.insert({kEllipseMask, (id)kCFBooleanTrue});
            break;
        }

        case ImageMaskTypeRounded: {
            const CKComponentViewAttribute kRoundedMask("imageview.roundedMask.variable", ^(UIView *view, id value){
                view.layer.masksToBounds = YES;
                view.layer.cornerRadius = cornerRadius;
                view.layer.mask = nil; // Clear any previous ellipse mask
            });
            maskedAttrs.insert({kRoundedMask, (id)kCFBooleanTrue});
            break;
        }

        case ImageMaskTypeNone:
        default:
            break;
    }

    return maskedAttrs;
}

@end
