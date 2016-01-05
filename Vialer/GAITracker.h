//
//  VialerGAITracker.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Google/Analytics.h>

@interface GAITracker : NSObject
+ (void)setupGAITracker;
+ (void)setupGAITrackerWithLogLevel:(GAILogLevel)logLevel andDryRun:(BOOL)dryRun;
+ (void)trackScreenForControllerName:(NSString *)name;
+ (void)acceptIncomingCallEvent;
+ (void)declineIncomingCallEvent;
+ (void)setupOutgoingSIPCallEvent;
+ (void)setupOutgoingConnectABCallEvent;

@end
