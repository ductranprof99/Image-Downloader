//
//  UIImageView+CNI.m
//  CNIUIKit
//

#import "UIImageView+CNI.h"
#import <objc/runtime.h>

static const void *CNIImageViewCurrentURLKey = &CNIImageViewCurrentURLKey;

@implementation UIImageView (CNI)

#pragma mark - Public API

- (void)cni_setImageWithURL:(NSURL *)URL {
  [self cni_setImageWithURL:URL
                placeholder:nil
                   priority:CNIResourcePriorityLow
        shouldSaveToStorage:YES
                 onProgress:nil
               onCompletion:nil];
}

- (void)cni_setImageWithURL:(NSURL *)URL placeholder:(UIImage *)placeholder {
  [self cni_setImageWithURL:URL
                placeholder:placeholder
                   priority:CNIResourcePriorityLow
        shouldSaveToStorage:YES
                 onProgress:nil
               onCompletion:nil];
}

- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(UIImage *)placeholder
                   priority:(CNIResourcePriority)priority {
  [self cni_setImageWithURL:URL
                placeholder:placeholder
                   priority:priority
        shouldSaveToStorage:YES
                 onProgress:nil
               onCompletion:nil];
}

- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(UIImage *)placeholder
                   priority:(CNIResourcePriority)priority
                 onProgress:(void (^)(CGFloat))progressBlock {
  [self cni_setImageWithURL:URL
                placeholder:placeholder
                   priority:priority
        shouldSaveToStorage:YES
                 onProgress:progressBlock
               onCompletion:nil];
}

- (void)cni_setImageWithURL:(NSURL *)URL
                placeholder:(UIImage *)placeholder
                   priority:(CNIResourcePriority)priority
        shouldSaveToStorage:(BOOL)shouldSave
                 onProgress:(void (^)(CGFloat))progressBlock
               onCompletion:(void (^)(UIImage *, NSError *, BOOL, BOOL))completionBlock {
  if (!URL) {
    self.image = placeholder;
    if (completionBlock) {
      completionBlock(nil, [NSError errorWithDomain:@"CNI"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"URL is nil"}],
                      NO, NO);
    }
    return;
  }

  // Cancel previous request if URL changed
  NSURL *currentURL = [self cni_currentURL];
  if (currentURL && ![currentURL isEqual:URL]) {
    [self cni_cancelImageLoading];
  }

  // Store current URL
  [self cni_setCurrentURL:URL];

  // Show placeholder immediately
  if (placeholder) {
    self.image = placeholder;
  }

  // Weak self for blocks
  __weak typeof(self) weakSelf = self;

  // Progress callback
  CNIImageProgressBlock progressBlockWrapper = nil;
  if (progressBlock) {
    progressBlockWrapper = ^(CGFloat progress) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        dispatch_async(dispatch_get_main_queue(), ^{
          progressBlock(progress);
        });
      }
    };
  }

  // Completion callback
  CNIImageCompletionBlock completionBlockWrapper = ^(
      UIImage *image,
      NSError *error,
      BOOL fromCache,
      BOOL fromStorage
  ) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    dispatch_async(dispatch_get_main_queue(), ^{
      // Only update if URL hasn't changed
      NSURL *currentLoadingURL = [strongSelf cni_currentURL];
      if ([currentLoadingURL isEqual:URL]) {
        if (image) {
          strongSelf.image = image;
        } else if (error && placeholder) {
          // Keep placeholder on error
          strongSelf.image = placeholder;
        }

        // Call user completion callback
        if (completionBlock) {
          completionBlock(image, error, fromCache, fromStorage);
        }
      }
    });
  };

  // Request image from CNIManager
  [[CNIManager sharedManager] requestImageAtURL:URL
                                       priority:priority
                            shouldSaveToStorage:shouldSave
                                       progress:progressBlockWrapper
                                     completion:completionBlockWrapper
                                         caller:self];
}

- (void)cni_cancelImageLoading {
  NSURL *currentURL = [self cni_currentURL];
  if (currentURL) {
    [[CNIManager sharedManager] cancelRequestForURL:currentURL caller:self];
    [self cni_setCurrentURL:nil];
  }
}

#pragma mark - Associated Objects

- (NSURL *)cni_currentURL {
  return objc_getAssociatedObject(self, CNIImageViewCurrentURLKey);
}

- (void)cni_setCurrentURL:(NSURL *)URL {
  objc_setAssociatedObject(self,
                           CNIImageViewCurrentURLKey,
                           URL,
                           OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
