//
//  NetworkImageViewBridge.h
//  ImageDownloaderComponentKit
//
//  Objective-C++ bridge for NetworkImageView
//  Required for ComponentKit C++ integration
//

#import <ComponentKit/ComponentKit.h>
#import <Foundation/Foundation.h>

@class NetworkImageViewOptions;

NS_ASSUME_NONNULL_BEGIN

/**
 Objective-C++ bridge for creating NetworkImageView components

 This bridge is necessary because ComponentKit uses C++ types that cannot be
 directly accessed from Swift. The Swift NetworkImageView class delegates to
 this bridge for actual component creation.
 */
@interface NetworkImageViewBridge : NSObject

/**
 Create a network image component with full configuration

 @param urlString Image URL
 @param size Component size
 @param options Configuration options (NetworkImageViewOptions)
 @param attributes View attributes for UIImageView
 @return CKComponent instance
 */
+ (CKComponent *)createComponentWithURL:(NSString *)urlString
                                   size:(const CKComponentSize &)size
                                options:(NetworkImageViewOptions *)options
                             attributes:(const CKViewComponentAttributeValueMap &)attributes;

@end

NS_ASSUME_NONNULL_END
