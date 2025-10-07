//
//  IDStorageMode.m
//  ImageDownloader
//
//  Created by ductd on 7/10/25.
//

#import "IDStorageMode.h"

@implementation IDStorageModeHelper

+ (BOOL)shouldSaveToStorageForMode:(IDStorageMode)mode {
    switch (mode) {
        case IDStorageModeNoStorage:
            return NO;
        case IDStorageModeHighPriorityLowStorage:
            return YES;
        case IDStorageModeFullStorage:
            return YES;
    }
}

+ (BOOL)isHighPriorityForMode:(IDStorageMode)mode {
    switch (mode) {
        case IDStorageModeNoStorage:
            return NO;
        case IDStorageModeHighPriorityLowStorage:
            return YES;
        case IDStorageModeFullStorage:
            return NO;
    }
}

+ (NSString *)descriptionForMode:(IDStorageMode)mode {
    switch (mode) {
        case IDStorageModeNoStorage:
            return @"No Storage";
        case IDStorageModeHighPriorityLowStorage:
            return @"High + Storage";
        case IDStorageModeFullStorage:
            return @"Full Storage";
    }
}

@end