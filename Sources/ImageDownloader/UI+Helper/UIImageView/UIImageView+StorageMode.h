//
//  UIImageView+StorageMode.h
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

#import <UIKit/UIKit.h>
#import "IDStorageMode.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (StorageMode)

- (void)loadImageWithURL:(NSURL *)url
             storageMode:(IDStorageMode)mode
             completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

- (void)cancelImageLoadingWithStorageMode;

@end

NS_ASSUME_NONNULL_END