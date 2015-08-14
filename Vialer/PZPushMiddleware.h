//
//  PZPushMiddleWare.h
//  Vialer
//
//  Created by Karsten Westra on 18/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;

@interface PZPushMiddleware : NSObject

- (NSString*)baseLink;

- (void)registerForVoIPNotifications;

- (void)handleReceivedNotificationForApplicationState:(UIApplicationState)state payload:(NSDictionary*)payload;

- (void)updateMiddleWareWithData:(NSDictionary*)data;

- (void)registerToken:(NSData*)token;
- (void)unregisterToken:(NSData*)token;

@end
