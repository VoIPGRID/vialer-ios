//
//  VialerGAITracker.h
//  Vialer
//
//  Created by Bob Voorneveld on 14/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAITracker : NSObject

+ (void)setupGAITracker;
+ (void)trackScreenForControllerName:(NSString *)name;
+ (void)acceptIncomingCallEvent;
+ (void)declineIncomingCallEvent;
+ (void)setupOutgoingSIPCallEvent;
+ (void)setupOutgoingConnectABCallEvent;

@end
