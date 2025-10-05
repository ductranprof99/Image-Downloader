//
//  CNIResourceModel.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

typedef NS_ENUM(NSInteger, CNIResourceState) {
    CNIResourceStateUnknown,
    CNIResourceStateDownloading,
    CNIResourceStateAvailable,
    CNIResourceStateFailed
};

typedef NS_ENUM(NSInteger, CNIResourcePriority) {
    CNIResourcePriorityLow,
    CNIResourcePriorityHigh
};

@interface CNIResourceModel : NSObject

@property (nonatomic, readonly) NSURL * _Nonnull URL;
@property (nonatomic, readonly) NSString *identifier; // MD5 hash of URL
@property (nonatomic, assign) CNIResourceState state;
@property (nonatomic, assign) CNIResourcePriority priority;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong, nullable) NSDate *lastAccessDate;
@property (nonatomic, assign) BOOL shouldSaveToStorage; // Flag for storage persistence

- (instancetype _Nonnull )initWithURL:(NSURL *_Nonnull)URL
                             priority:(CNIResourcePriority)priority;
- (void)updateLastAccessDate;

@end
