//
//  CNIImageView.m
//  CNIUIKit
//

#import "CNIImageView.h"

@implementation CNIImageView {
  NSURL *_currentURL;
  BOOL _isLoading;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self _commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self _commonInit];
  }
  return self;
}

- (void)_commonInit {
  _priority = CNIResourcePriorityLow;
  _shouldSaveToStorage = YES;
  _isLoading = NO;
  self.contentMode = UIViewContentModeScaleAspectFill;
  self.clipsToBounds = YES;
}

- (void)dealloc {
  [self cancelLoading];
}

#pragma mark - Public API

- (void)loadImageFromURL:(NSURL *)URL {
  [self loadImageFromURL:URL
             placeholder:self.placeholderImage
                priority:self.priority
     shouldSaveToStorage:self.shouldSaveToStorage];
}

- (void)loadImageFromURL:(NSURL *)URL placeholder:(UIImage *)placeholder {
  [self loadImageFromURL:URL
             placeholder:placeholder
                priority:self.priority
     shouldSaveToStorage:self.shouldSaveToStorage];
}

- (void)loadImageFromURL:(NSURL *)URL
             placeholder:(UIImage *)placeholder
                priority:(CNIResourcePriority)priority
     shouldSaveToStorage:(BOOL)shouldSave {
  if (!URL) {
    self.image = placeholder;
    return;
  }

  // Cancel previous request if URL changed
  if (_currentURL && ![_currentURL isEqual:URL]) {
    [self cancelLoading];
  }

  _currentURL = URL;
  _isLoading = YES;

  // Show placeholder immediately
  if (placeholder) {
    self.image = placeholder;
  }

  // Weak self for blocks
  __weak typeof(self) weakSelf = self;

  // Progress callback
  CNIImageProgressBlock progressBlock = nil;
  if (self.onProgress) {
    progressBlock = ^(CGFloat progress) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf && strongSelf.onProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
          strongSelf.onProgress(progress);
        });
      }
    };
  }

  // Completion callback
  CNIImageCompletionBlock completionBlock = ^(
      UIImage *image,
      NSError *error,
      BOOL fromCache,
      BOOL fromStorage
  ) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;

    dispatch_async(dispatch_get_main_queue(), ^{
      // Only update if URL hasn't changed
      if ([strongSelf->_currentURL isEqual:URL]) {
        strongSelf->_isLoading = NO;

        if (image) {
          strongSelf.image = image;
        } else if (error && placeholder) {
          // Keep placeholder on error
          strongSelf.image = placeholder;
        }

        // Call user completion callback
        if (strongSelf.onCompletion) {
          strongSelf.onCompletion(image, error, fromCache, fromStorage);
        }
      }
    });
  };

  // Request image from CNIManager
  [[CNIManager sharedManager] requestImageAtURL:URL
                                       priority:priority
                            shouldSaveToStorage:shouldSave
                                       progress:progressBlock
                                     completion:completionBlock
                                         caller:self];
}

- (void)cancelLoading {
  if (_currentURL) {
    [[CNIManager sharedManager] cancelRequestForURL:_currentURL caller:self];
    _currentURL = nil;
    _isLoading = NO;
  }
}

#pragma mark - Properties

- (NSURL *)imageURL {
  return _currentURL;
}

- (BOOL)isLoading {
  return _isLoading;
}

@end
