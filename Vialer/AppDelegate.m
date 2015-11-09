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
#import "LogInViewController.h"
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

@interface AppDelegate()
@property (nonatomic, strong) RootViewController *rootViewController;
@property (nonatomic, strong) LogInViewController *loginViewController;
@end

@implementation AppDelegate

#pragma mark - UIApplication delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [GAITracker setupGAITracker];
    [self setupConnectivity];
    [self setupAppearance];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];

    [self setupLogin];

    NSSetUncaughtExceptionHandler(&HandleExceptions);

    return YES;
}

#pragma mark - setup helper methods

- (void)setupConnectivity {
#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
#endif
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[PZPushMiddleware sharedInstance] registerForVoIPNotifications];
    [[ConnectionHandler sharedConnectionHandler] start];
}

- (void)setupAppearance {
    Configuration *config = [Configuration new];

    // Customize TabBar
    [UITabBar appearance].tintColor = [config tintColorForKey:kTintColorTabBar];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setTintColor:[config tintColorForKey:kTintColorTabBar]];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        [UITabBar appearance].barTintColor = [UIColor colorWithRed:(247 / 255.f) green:(247 / 255.f) blue:(247 / 255.f) alpha:1.f];
    }

    // Customize NavigationBar
    [UINavigationBar appearance].tintColor = [config tintColorForKey:kTintColorNavigationBar];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:(248 / 255.f) green:(248 / 255.f) blue:(248 / 255.f) alpha:1.f];
    }
}

- (void)setupLogin {
    // Handler for failed authentications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];

    //Everybody, upgraders and new users, will see the onboarding. If you were logged in at v1.x, you will be logged in on
    //v2.x and start onboarding at the "configure numbers view".

    //TODO: Why not login again. What if the user was deactivated on the platform?
    if (![SystemUser currentUser].isLoggedIn) {
        //Not logged in, not v21.x, nor in v2.x
        [self showOnboarding:OnboardingScreenLogin];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"v2.0_MigrationComplete"]){
        //Also show the Mobile number onboarding screen
        [self showOnboarding:OnboardingScreenConfigure];
    } else {
        [[SystemUser currentUser] checkSipStatus];
    }
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

#pragma mark - UIApplicationDelegate methods
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[SystemUser currentUser] updateSIPAccountWithSuccess:^(BOOL success) {
        if (success) {
            [[PZPushMiddleware sharedInstance] updateDeviceRecord];
        }
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // End all active calls when the app is terminated
    for (GSCall *activeCall in [GSCall activeCalls]) {
        [activeCall end];
    }
    [[ConnectionHandler sharedConnectionHandler] sipDisconnect:^{
        NSLog(@"%s SIP Disconnected", __PRETTY_FUNCTION__);
    }];
}

#pragma mark - Handle person(s) & calls
- (BOOL)handlePerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (property == kABPersonPhoneProperty) {
        ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++) {
            if (identifier == ABMultiValueGetIdentifierAtIndex(multiPhones, i)) {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
                CFRelease(multiPhones);

                NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
                CFRelease(phoneNumberRef);

                NSString *fullName = (__bridge NSString *)ABRecordCopyCompositeName(person);
                if (!fullName) {
                    NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                    NSString *middleName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
                    NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
                    if (firstName) {
                        fullName = [NSString stringWithFormat:@"%@ %@%@", firstName, [middleName length] ? [NSString stringWithFormat:@"%@ ", middleName] : @"", lastName];
                    }
                }

                [self handlePhoneNumber:phoneNumber forContact:fullName];
            }
        }
    }
    return NO;
}

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact {
    [self.rootViewController handlePhoneNumber:phoneNumber forContact:contact];
}

- (void)handlePhoneNumber:(NSString *)phoneNumber {
    [self handlePhoneNumber:phoneNumber forContact:nil];
}

- (void)handleSipCall:(GSCall *)sipCall {
    return [self.rootViewController handleSipCall:sipCall];
}

#pragma mark - Notification actions
- (void)showOnboarding:(OnboardingScreens)screenToShow {
    // Check if the loginViewController is created, and if present
    NSLog(@"self.loginViewController.presentingViewController %@", self.loginViewController.presentingViewController);
    if (self.loginViewController == nil || !self.loginViewController.presentingViewController) {
        // Create a new instance, and present it.
        self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];
        if (!self.loginViewController.presentingViewController) {
            self.loginViewController.screenToShow = screenToShow;
            self.loginViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

            // Make sure we have the current presenting viewcontroller.
            UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (topRootViewController.presentedViewController) {
                topRootViewController = topRootViewController.presentedViewController;
            }
            [topRootViewController presentViewController:self.loginViewController animated:YES completion:nil];
        }
    }
}

- (void)loginFailedNotification:(NSNotification *)notification {
    [self showOnboarding:OnboardingScreenLogin];
}

@end
