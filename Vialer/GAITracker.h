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

/**
 *  Incoming VoIPPush notification was responded with available to middleware.
 */
+ (void)acceptedPushNotificationEvent;

/**
 *  Incoming VoIPPush notification was responded with unavailable to middleware.
 */
+ (void)rejectedPushNotificationEvent;

/**
 *  Exception when the registration failed on the middleware.
 */
+ (void)regististrationFailedWithMiddleWareException;

/**
 *  This method will log the time took to respond to the incoming push notification and respond to the middleware.
 *
 *  @param responseTime NSTimeInterval with the time it took to respond.
 */
+ (void)timeToRespondToIncomingPushNotification:(NSTimeInterval)responseTime;

@end
