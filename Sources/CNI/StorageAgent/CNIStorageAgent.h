//
//  CNIStorageAgent.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CNIStorageAgent : NSObject

@property (nonatomic, assign) NSUInteger diskCacheSizeLimit; // bytes (0 = unlimited)

- (instancetype _Nonnull )initWithStoragePath:(NSString * _Nullable)storagePath;

// Synchronous operations (checks existence)
- (BOOL)hasImageForURL:(NSURL *_Nonnull)URL;

// Asynchronous read
- (void)imageForURL:(NSURL *_Nonnull)URL
         completion:(void (^_Nullable)(UIImage * _Nullable image))completion;

// Asynchronous write
- (void)saveImage:(UIImage *_Nonnull)image
           forURL:(NSURL *_Nonnull)URL
       completion:(void (^ _Nullable)(BOOL success))completion;

// Asynchronous delete
- (void)removeImageForURL:(NSURL *_Nonnull)URL
               completion:(void (^ _Nullable)(BOOL success))completion;

// Clear operations
- (void)clearAllStorage:(void (^ _Nullable)(BOOL success))completion;

// File management
- (NSString *_Nullable)filePathForURL:(NSURL *_Nonnull)URL; // Returns full file path
- (NSUInteger)currentStorageSize; // Total bytes used

@end
