//
//  CNINetworkQueue.h
//  CKTest
//
//  Created by CNI on 30/9/25.
//

#import <Foundation/Foundation.h>
#import <CNI/CNINetworkTask.h>

@interface CNINetworkQueue : NSObject

// Enqueue task with priority
- (void)enqueueTask:(CNINetworkTask *_Nonnull)task;

// Dequeue next task based on priority (High priority first)
- (CNINetworkTask * _Nullable)dequeueTask;

// Peek at next task without removing
- (CNINetworkTask * _Nullable)peekNextTask;

// Find task by URL
- (CNINetworkTask * _Nullable)taskForURL:(NSURL *_Nonnull)URL;

// Remove specific task
- (void)removeTask:(CNINetworkTask *_Nonnull)task;

// Check if queue is empty
- (BOOL)isEmpty;

// Get queue counts
- (NSUInteger)highPriorityCount;
- (NSUInteger)lowPriorityCount;
- (NSUInteger)totalCount;

// Clear all tasks
- (void)clearAllTasks;

@end
