//
//  BackgroundTaskHandler.h
//  Vialer
//
//  Created by Reinier Wieringa on 02/02/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BackgroundTaskHandler : NSObject

+ (BackgroundTaskHandler *)sharedBackgroundTaskHandler;

- (UIBackgroundTaskIdentifier)startBackgroundTask;
- (void)endAllBackgroundTasks;

@end
