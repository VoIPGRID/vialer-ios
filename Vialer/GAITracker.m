//
//  VialerGAITracker.m
//  Vialer
//
//  Created by Bob Voorneveld on 14/10/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "GAITracker.h"

#import <Google/Analytics.h>

@implementation GAITracker

+ (void)setupGAITracker {
    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);

    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
#ifdef DEBUG
    gai.logger.logLevel = kGAILogLevelVerbose;  // remove before app releaseAppDelegate.m
    gai.dryRun = YES;    // NOTE: Set to YES to disable tracking
#endif
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
