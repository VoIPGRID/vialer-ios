//
//  BackgroundTaskHandler.m
//  Vialer
//
//  Created by Reinier Wieringa on 02/02/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "BackgroundTaskHandler.h"

@interface BackgroundTaskHandler()
@property (nonatomic, strong) NSMutableArray *backgroundTaskList;
@property (assign) UIBackgroundTaskIdentifier masterBackgroundTaskId;
@end

@implementation BackgroundTaskHandler

+ (BackgroundTaskHandler *)sharedBackgroundTaskHandler {
    static dispatch_once_t pred;
    static BackgroundTaskHandler *_sharedBackgroundTaskHandler = nil;
    
    dispatch_once(&pred, ^{
		_sharedBackgroundTaskHandler = [[self alloc] init];
	});
    return _sharedBackgroundTaskHandler;
}

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundTaskList = [NSMutableArray array];
        self.masterBackgroundTaskId = UIBackgroundTaskInvalid;
    }
    return self;
}

- (UIBackgroundTaskIdentifier)startBackgroundTask {
    UIApplication *application = [UIApplication sharedApplication];

    UIBackgroundTaskIdentifier identifier = UIBackgroundTaskInvalid;
    if ([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
        identifier = [application beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Background task %lu expired", (unsigned long)identifier);
        }];

        if (self.masterBackgroundTaskId == UIBackgroundTaskInvalid) {
            self.masterBackgroundTaskId = identifier;
            NSLog(@"Started master task %lu", (unsigned long)self.masterBackgroundTaskId);
        } else {
            NSLog(@"Started background task %lu", (unsigned long)identifier);
            [self.backgroundTaskList addObject:@(identifier)];
            [self cleanUpBackgroundTasks];
        }
    }
    return identifier;
}

- (void)cleanUpBackgroundTasks {
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(endBackgroundTask:)]) {
        NSUInteger count = self.backgroundTaskList.count;
        for (NSUInteger i = 1; i < count; i++) {
            UIBackgroundTaskIdentifier identifier = [[self.backgroundTaskList objectAtIndex:0] integerValue];
            NSLog(@"Ending background task with id %lu", (unsigned long)identifier);
            [application endBackgroundTask:identifier];
            [self.backgroundTaskList removeObjectAtIndex:0];
        }

        if (self.backgroundTaskList.count > 0){
            NSLog(@"Kept background task id %@", [self.backgroundTaskList objectAtIndex:0]);
        }
    }
}

- (void)endAllBackgroundTasks {
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(endBackgroundTask:)]) {
        NSUInteger count = self.backgroundTaskList.count;
        for (NSUInteger i = 0; i < count; i++) {
            UIBackgroundTaskIdentifier identifier = [[self.backgroundTaskList objectAtIndex:0] integerValue];
            NSLog(@"Ending background task with id %lu", (unsigned long)identifier);
            [application endBackgroundTask:identifier];
            [self.backgroundTaskList removeObjectAtIndex:0];
        }
        if (self.backgroundTaskList.count > 0) {
            NSLog(@"Kept background task id %@", [self.backgroundTaskList objectAtIndex:0]);
        }
        NSLog(@"No more background tasks running");
        [application endBackgroundTask:self.masterBackgroundTaskId];
        self.masterBackgroundTaskId = UIBackgroundTaskInvalid;
    }
}

@end
