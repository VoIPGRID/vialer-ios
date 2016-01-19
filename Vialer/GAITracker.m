//
//  VialerGAITracker.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "GAITracker.h"

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

@end
