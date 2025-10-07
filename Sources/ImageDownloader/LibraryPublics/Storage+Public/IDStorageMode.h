//
//  IDStorageMode.h
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IDStorageMode) {
    IDStorageModeNoStorage = 0,
    IDStorageModeHighPriorityLowStorage = 1,
    IDStorageModeFullStorage = 2
};

NS_ASSUME_NONNULL_BEGIN

@interface IDStorageModeHelper : NSObject

+ (BOOL)shouldSaveToStorageForMode:(IDStorageMode)mode;
+ (BOOL)isHighPriorityForMode:(IDStorageMode)mode;
+ (NSString *)descriptionForMode:(IDStorageMode)mode;

@end

NS_ASSUME_NONNULL_END