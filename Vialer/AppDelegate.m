//
//  AppDelegate.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"
#ifdef DEBUG
#import "SDStatusBarManager.h"
#endif
#import "SSKeychain.h"

#import "APNSHandler.h"
#import "GAITracker.h"
#import "PZPushMiddleware.h"
#import "SystemUser.h"

@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [[APNSHandler sharedHandler] registerForVoIPNotifications];

    //Only when the app is run for screenshot purposes do the following:
    if ([[self class] isSnapshotScreenshotRun]) {
#ifdef DEBUG
        [[SDStatusBarManager sharedInstance] setTimeString:@"09:41"];
        [[SDStatusBarManager sharedInstance] enableOverrides];
#endif
        [GAITracker setupGAITrackerWithLogLevel:kGAILogLevelNone andDryRun:YES];

        //Clear out the userdefaults
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    } else {
        [GAITracker setupGAITracker];
    }

#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
#endif

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SystemUser currentUser] updateSIPAccountWithSuccess:^(BOOL success, NSError *error) {
            if (success) {
                [[PZPushMiddleware sharedInstance] updateDeviceRecord];
            }
        }];
    });
}

#pragma mark - setup helper methods

+ (BOOL)isSnapshotScreenshotRun {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FASTLANE_SNAPSHOT"];
}

#pragma mark - UIApplication notification delegate

//- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)()) completionHandler {
//    NSLog(@"Received push notification: %@, identifier: %@", notification, identifier); // iOS 8
//    if (application.applicationState != UIApplicationStateActive) {
//    }
//}
//
//- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
//    if (application.applicationState != UIApplicationStateActive) { //
//    }
//}

#pragma mark - Handle person(s) & calls
- (void)handleSipCall:(GSCall *)sipCall {
    // TODO: fix sip call
}

@end
