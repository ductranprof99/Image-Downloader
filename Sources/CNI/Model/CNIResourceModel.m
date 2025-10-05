//
//  CNIResourceModel.m
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <CNI/CNIResourceModel.h>


@implementation CNIResourceModel

- (instancetype)initWithURL:(NSURL *)URL priority:(CNIResourcePriority)priority {
    if (self = [super init]) {
        _URL = [URL copy];
        _identifier = [self _generateIdentifierForURL:URL];
        _priority = priority;
        _state = CNIResourceStateUnknown;
        _progress = 0.0;
        _shouldSaveToStorage = YES; // Default: save to storage
        _lastAccessDate = [NSDate date];
    }
    return self;
}

- (void)updateLastAccessDate {
    _lastAccessDate = [NSDate date];
}

#pragma mark - Private

- (NSString *)_generateIdentifierForURL:(NSURL *)URL {
    NSString *urlString = URL.absoluteString;
    const char *cStr = [urlString UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", digest[i]];
    }

    return hash;
}

@end
