//
//  VialerGAITracker.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Google/Analytics.h>

@interface GAITracker : NSObject
/**
 *  Configures the shared GA Tracker instance with the default info log level
 *  and sets dry run according to DEBUG being set or not.
 */
+ (void)setupGAITracker;

/**
 *  Configures the shared GA Tracker instance with the parameters provided.
 *
 *  @param logLevel The GA log level you want to configure the shared instance with
 *  @param dryRun   Boolean indicating GA to run in dry run mode or not.
 */
+ (void)setupGAITrackerWithLogLevel:(GAILogLevel)logLevel andDryRun:(BOOL)dryRun;

/**
 *  Tracks a screen with the given name. If the name contains "ViewController" this is removed.
 *
 *  @param name The screen name to track
 */
+ (void)trackScreenForControllerName:(NSString *)name;

/**
 *  Indication a call event is received from the SIP Proxy and the app is ringing.
 */
+ (void)incomingCallRingingEvent;

/**
 *  The incoming call is accepted.
 */
+ (void)acceptIncomingCallEvent;

/**
 *  The incoming call is rejected.
 */
+ (void)declineIncomingCallEvent;

/**
 *  The incoming call is rejected because there is another call in progress.
 */
+ (void)declineIncomingCallBecauseAnotherCallInProgressEvent;

/**
 *  Event used to track an outbound SIP call.
 */
+ (void)setupOutgoingSIPCallEvent;

/**
 *  Event used to track an outbound ConnectAB (aka two step) call.
 */
+ (void)setupOutgoingConnectABCallEvent;

/**
 *  Incoming VoIPPush notification was responded with available to middleware.
 *
 *  @param an int indicating the current connection value (as described in the "Google Analytics events for all Mobile apps" document
 */
+ (void)acceptedPushNotificationEventWithConnectionValue:(int)connectionValue;

/**
 *  Incoming VoIPPush notification was responded with unavailable to middleware.
 *
 *  @param an int indicating the current connection value (as described in the "Google Analytics events for all Mobile apps" document
 */
+ (void)rejectedPushNotificationEventWithConnectionValue:(int)connectionValue;

/**
 *  Exception when the registration failed on the middleware.
 */
+ (void)registrationFailedWithMiddleWareException;

/**
 *  This method will log the time took to respond to the incoming push notification and respond to the middleware.
 *
 *  @param responseTime NSTimeInterval with the time it took to respond.
 */
+ (void)timeToRespondToIncomingPushNotification:(NSTimeInterval)responseTime;

@end
