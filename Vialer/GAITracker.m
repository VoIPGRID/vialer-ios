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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Configure tracker from GoogleService-Info.plist.
        NSError *configureError;
        [[GGLContext sharedInstance] configureWithError:&configureError];
        NSAssert(!configureError, @"Error configuring Google services: %@", configureError);

        // Optional: configure GAI options.
        GAI *gai = [GAI sharedInstance];
        gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
#ifdef DEBUG
        gai.logger.logLevel = kGAILogLevelInfo;  // remove before app releaseAppDelegate.m
        [gai setDryRun:YES];   // NOTE: Set to YES to disable tracking
#endif
    });
}

+ (void)trackScreenForControllerName:(NSString *)name {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:[name stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    });
}

+ (void)acceptIncomingCallEvent {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                              action:@"Inbound"
                                                               label:@"Accepted"
                                                               value:nil] build]];
    });
}

+ (void)declineIncomingCallEvent {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                              action:@"Inbound"
                                                               label:@"Declined"
                                                               value:nil] build]];
    });
}

+ (void)setupOutgoingSIPCallEvent {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                              action:@"Outbound"
                                                               label:@"SIP"
                                                               value:nil] build]];
    });
}

+ (void)setupOutgoingConnectABCallEvent {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                              action:@"Outbound"
                                                               label:@"ConnectAB"
                                                               value:nil] build]];
    });
}

@end
