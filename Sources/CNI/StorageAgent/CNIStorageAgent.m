//
//  CNIStorageAgent.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNIStorageAgent.h>
#import <CommonCrypto/CommonDigest.h>

@implementation CNIStorageAgent {
    NSFileManager *_fileManager;
    NSURL *_storageURL;
    dispatch_queue_t _ioQueue;
}

- (instancetype)init {
    return [self initWithStoragePath:nil];
}

- (instancetype)initWithStoragePath:(NSString *)storagePath {
    if (self = [super init]) {
        _fileManager = [NSFileManager defaultManager];
        _ioQueue = dispatch_queue_create(
            "com.cni.storageagent.io",
            DISPATCH_QUEUE_SERIAL
        );

        if (storagePath) {
            _storageURL = [NSURL fileURLWithPath:storagePath];
        } else {
            _storageURL = [self _defaultStorageDirectory];
        }

        [self _createStorageDirectoryIfNeeded];
    }
    return self;
}

- (BOOL)hasImageForURL:(NSURL *)URL {
    if (!URL) return NO;

    NSString *filePath = [self filePathForURL:URL];
    return [_fileManager fileExistsAtPath:filePath];
}

- (void)imageForURL:(NSURL *)URL completion:(void (^)(UIImage *))completion {
    if (!URL) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
        return;
    }

    dispatch_async(_ioQueue, ^{
        NSString *filePath = [self filePathForURL:URL];
        UIImage *image = nil;

        if ([_fileManager fileExistsAtPath:filePath]) {
            NSData *imageData = [NSData dataWithContentsOfFile:filePath];
            if (imageData) {
                image = [UIImage imageWithData:imageData];
            }
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            });
        }
    });
}

- (void)saveImage:(UIImage *)image
           forURL:(NSURL *)URL
       completion:(void (^)(BOOL))completion
{
    if (!image || !URL) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        return;
    }

    dispatch_async(_ioQueue, ^{
        NSString *filePath = [self filePathForURL:URL];
        NSData *imageData = UIImagePNGRepresentation(image);

        BOOL success = NO;
        if (imageData) {
            success = [imageData writeToFile:filePath atomically:YES];
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success);
            });
        }
    });
}

- (void)removeImageForURL:(NSURL *)URL completion:(void (^)(BOOL))completion {
    if (!URL) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        return;
    }

    dispatch_async(_ioQueue, ^{
        NSString *filePath = [self filePathForURL:URL];
        BOOL success = NO;

        if ([_fileManager fileExistsAtPath:filePath]) {
            NSError *error = nil;
            success = [_fileManager removeItemAtPath:filePath error:&error];
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success);
            });
        }
    });
}

- (void)clearAllStorage:(void (^)(BOOL))completion {
    dispatch_async(_ioQueue, ^{
        NSError *error = nil;
        BOOL success = [_fileManager removeItemAtURL:_storageURL error:&error];

        if (success) {
            [self _createStorageDirectoryIfNeeded];
        }

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success);
            });
        }
    });
}

- (NSString *)filePathForURL:(NSURL *)URL {
    NSString *filename = [self _filenameForURL:URL];
    return [_storageURL.path stringByAppendingPathComponent:filename];
}

- (NSUInteger)currentStorageSize {
    __block NSUInteger totalSize = 0;

    dispatch_sync(_ioQueue, ^{
        NSArray *files = [_fileManager contentsOfDirectoryAtPath:_storageURL.path error:nil];

        for (NSString *file in files) {
            NSString *filePath = [_storageURL.path stringByAppendingPathComponent:file];
            NSDictionary *attributes = [_fileManager attributesOfItemAtPath:filePath error:nil];
            totalSize += [attributes fileSize];
        }
    });

    return totalSize;
}

#pragma mark - Private

- (NSURL *)_defaultStorageDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths firstObject];
    return [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:@"CNIImageStorage"]];
}

- (void)_createStorageDirectoryIfNeeded {
    if (![_fileManager fileExistsAtPath:_storageURL.path]) {
        [_fileManager createDirectoryAtURL:_storageURL
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
}

- (NSString *)_filenameForURL:(NSURL *)URL {
    NSString *urlString = URL.absoluteString;

    // MD5 hash for guaranteed uniqueness
    const char *cStr = [urlString UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }

    // Add readable suffix from URL for debugging
    NSString *lastComponent = URL.lastPathComponent;
    if (lastComponent.length > 0) {
        // Sanitize filename
        NSCharacterSet *invalidChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSString *sanitized = [[lastComponent componentsSeparatedByCharactersInSet:invalidChars] componentsJoinedByString:@"_"];

        // Limit length
        if (sanitized.length > 50) {
            sanitized = [sanitized substringToIndex:50];
        }

        return [NSString stringWithFormat:@"%@_%@", hash, sanitized];
    }

    // Fallback: just hash with extension
    NSString *extension = URL.pathExtension.length > 0 ? URL.pathExtension : @"png";
    return [NSString stringWithFormat:@"%@.%@", hash, extension];
}

@end