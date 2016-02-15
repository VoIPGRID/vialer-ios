//
//  AppDelegate.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"
@import AVFoundation;
#ifdef DEBUG
#import "SDStatusBarManager.h"
#endif
#import "SSKeychain.h"

#import "APNSHandler.h"
#import "HDLumberjackLogFormatter.h"
#import "GAITracker.h"
#import "PZPushMiddleware.h"
#import "SIPUtils.h"
#import "SystemUser.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>


@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [[APNSHandler sharedHandler] registerForVoIPNotifications];
    [self setupCocoaLumberjackLogging];

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedSIPCredentials:) name:SystemUserSIPCredentialsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:SystemUserLogoutNotification object:nil];
    if ([SystemUser currentUser].sipAllowed) {
        [self updatedSIPCredentials:nil];
    }

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

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - setup helper methods

+ (BOOL)isSnapshotScreenshotRun {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FASTLANE_SNAPSHOT"];
}

- (void)setupCocoaLumberjackLogging {
    //Add the Terminal and TTY(XCode console) loggers to CocoaLumberjack (simulate the default NSLog behaviour)
    HDLumberjackLogFormatter* logFormat = [[HDLumberjackLogFormatter alloc] init];

    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter: logFormat];
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormat];
    [ttyLogger setColorsEnabled:YES];

    //Give INFO a color
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];

    [DDLog addLogger:aslLogger];
    [DDLog addLogger:ttyLogger];
}

# pragma mark - Notifications

- (void)updatedSIPCredentials:(NSNotification *)notification {
    if ([SystemUser currentUser].sipAccount) {
        [SIPUtils setupSIPEndpoint];
    } else {
        [SIPUtils removeSIPEndpoint];
    }
}

- (void)userLoggedOut:(NSNotification *)notification {
    [SIPUtils removeSIPEndpoint];
}

#pragma mark - Handle person(s) & calls
- (void)handleSipCall:(GSCall *)sipCall {
    // TODO: fix sip call
}

@end
