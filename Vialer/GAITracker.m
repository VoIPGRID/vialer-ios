//
//  VialerGAITracker.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "GAITracker.h"

typedef NS_ENUM(NSInteger, CustomGoogleAnalyticsDimension) {
    CustomGoogleAnalyticsDimensionClientID = 1,
};

@implementation GAITracker

+ (void)setupGAITracker {
    BOOL dryRun = NO;
#ifdef DEBUG
    dryRun = YES;
#endif
    GAILogLevel logLevel = kGAILogLevelInfo;
    [[self class] setupGAITrackerWithLogLevel:logLevel andDryRun:dryRun];
}

+ (void)setupGAITrackerWithLogLevel:(GAILogLevel)logLevel andDryRun:(BOOL)dryRun {
    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);

    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
    gai.logger.logLevel = kGAILogLevelInfo;  // remove before app releaseAppDelegate.m
    [gai setDryRun:dryRun];   // NOTE: Set to YES to disable tracking
}

+ (void)trackScreenForControllerName:(NSString *)name {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:[name stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+ (void)setClientIDCustomDimension:(NSString *)clientID {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:[GAIFields customDimensionForIndex:CustomGoogleAnalyticsDimensionClientID] value:clientID];
}

+ (void)incomingCallRingingEvent {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                          action:@"Inbound"
                                                           label:@"Ringing"
                                                           value:nil] build]];
}

+ (void)acceptIncomingCallEvent {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                          action:@"Inbound"
                                                           label:@"Accepted"
                                                           value:nil] build]];
}

+ (void)declineIncomingCallEvent {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                          action:@"Inbound"
                                                           label:@"Declined"
                                                           value:nil] build]];
}

+ (void)declineIncomingCallBecauseAnotherCallInProgressEvent {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                          action:@"Inbound"
                                                           label:@"Declined - Another call in progress"
                                                           value:nil] build]];
}

+ (void)setupOutgoingSIPCallEvent {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                          action:@"Outbound"
                                                           label:@"SIP"
                                                           value:nil] build]];
}

+ (void)setupOutgoingConnectABCallEvent {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                          action:@"Outbound"
                                                           label:@"ConnectAB"
                                                           value:nil] build]];
}

+ (void)acceptedPushNotificationEventWithConnectionTypeAsString:(NSString *)connectionTypeString {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"middleware"
                                                          action:@"accepted"
                                                           label:connectionTypeString
                                                           value:nil] build]];
}

+ (void)rejectedPushNotificationEventWithConnectionTypeAsString:(NSString *)connectionTypeString {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"middleware"
                                                          action:@"rejected"
                                                           label:connectionTypeString
                                                           value:nil] build]];
}

+ (void)registrationFailedWithMiddleWareException {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:@"Failed middleware registration" withFatal:@NO] build]];
}

+ (void)timeToRespondToIncomingPushNotification:(NSTimeInterval)responseTime {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:@"middleware"
                                                         interval:@((NSUInteger)(responseTime * 1000))
                                                             name:@"response time"
                                                            label:nil] build]];
}

@end
