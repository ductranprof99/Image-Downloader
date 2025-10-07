//
//  UIImageView+StorageMode.m
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

#import "UIImageView+StorageMode.h"
@import ImageDownloader;

@implementation UIImageView (StorageMode)

- (void)loadImageWithURL:(NSURL *)url
             storageMode:(IDStorageMode)mode
             completion:(nullable void (^)(UIImage * _Nullable, NSError * _Nullable))completion {
    
    [self setImageObjCWith:url
                placeholder:nil
                  priority:[IDStorageModeHelper isHighPriorityForMode:mode] ? ResourcePriorityHigh : ResourcePriorityLow
                completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
                    if (completion) {
                        completion(image, error);
                    }
                }];
}

- (void)cancelImageLoadingWithStorageMode {
    [self cancelImageLoadingObjC];
}

@end