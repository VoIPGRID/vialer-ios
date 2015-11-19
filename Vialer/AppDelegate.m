//
//  AppDelegate.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "ConnectionHandler.h"
#import "GAITracker.h"
#import "Gossip+Extra.h"
#import "PZPushMiddleware.h"
#import "RootViewController.h"
#import "SystemUser.h"
#import "UIAlertView+Blocks.h"
#import "VoIPGRIDRequestOperationManager.h"

#import <AVFoundation/AVFoundation.h>

#import "AFNetworkActivityLogger.h"
#import "AFNetworkReachabilityManager.h"
#import "SSKeychain.h"


#define VOIP_TOKEN_STORAGE_KEY @"VOIP-TOKEN"

@interface AppDelegate() <PKPushRegistryDelegate>
@property (nonatomic, strong) RootViewController *rootViewController;
@end

@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [GAITracker setupGAITracker];
    [self setupConnectivity];

    NSSetUncaughtExceptionHandler(&HandleExceptions);

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SystemUser currentUser] updateSIPAccountWithSuccess:^(BOOL success) {
            if (success) {
                [[PZPushMiddleware sharedInstance] updateDeviceRecord];
            }
        }];
    });
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // End all active calls when the app is terminated
    for (GSCall *activeCall in [GSCall activeCalls]) {
        [activeCall end];
    }
    [[ConnectionHandler sharedConnectionHandler] sipDisconnect:^{
        NSLog(@"%s SIP Disconnected", __PRETTY_FUNCTION__);
    }];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - setup helper methods

- (void)setupConnectivity {
#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
#endif
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];

    // TODO: fix SIP
//    [[PZPushMiddleware sharedInstance] registerForVoIPNotifications];
//    [[ConnectionHandler sharedConnectionHandler] start];
}

#pragma mark - View Controllers
- (RootViewController *)rootViewController {
    if (!_rootViewController) {
        _rootViewController = [[RootViewController alloc] init];
    }
    return _rootViewController;
}

#pragma mark - UIApplication notification delegate
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)()) completionHandler {
    NSLog(@"Received push notification: %@, identifier: %@", notification, identifier); // iOS 8
    if (application.applicationState != UIApplicationStateActive) {
        [[ConnectionHandler sharedConnectionHandler] handleLocalNotification:notification withActionIdentifier:identifier];
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (application.applicationState != UIApplicationStateActive) { //
        [[ConnectionHandler sharedConnectionHandler] handleLocalNotification:notification withActionIdentifier:nil];
    }
}

#pragma mark - PKPushRegistray management
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    NSLog(@"%s Incoming push notification of type: %@", __PRETTY_FUNCTION__, type);
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    NSDictionary *payloadDict = [payload dictionaryPayload];
    [[PZPushMiddleware sharedInstance] handleReceivedNotificationForApplicationState:state payload:payloadDict];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    NSLog(@"Registration successful, bundle identifier: %@, device token: %@", [NSBundle.mainBundle bundleIdentifier], credentials.token);
    if (credentials.token) {
        [[PZPushMiddleware sharedInstance] updateDeviceRecordForToken:credentials.token];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    NSData *token = [registry pushTokenForType:type];
    if (token) {
        [[PZPushMiddleware sharedInstance] unregisterToken:[PZPushMiddleware deviceTokenStringFromData:token]
                                             andSipAccount:[SystemUser currentUser].sipAccount];
    }
}

#pragma mark - Exception handling
void HandleExceptions(NSException *exception) {
    NSLog(@"The app has encountered an unhandled exception: %@", [exception debugDescription]);
}

#pragma mark - Handle person(s) & calls

- (void)handleSipCall:(GSCall *)sipCall {
    return [self.rootViewController handleSipCall:sipCall];
}

@end
