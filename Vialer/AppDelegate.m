//
//  AppDelegate.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "SystemUser.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "LogInViewController.h"
#import "CallingViewController.h"
#import "SIPCallingViewController.h"
#import "SIPIncomingViewController.h"
#import "ContactsViewController.h"
#import "RecentsViewController.h"
#import "DialerViewController.h"

#import "SideMenuViewController.h"
#import "ConnectionHandler.h"
#import "Gossip+Extra.h"
#import "SSKeychain.h"

#import "AFNetworkActivityLogger.h"
#import "AFNetworkReachabilityManager.h"
#import "UIAlertView+Blocks.h"
#import "MMDrawerController.h"

#import <AVFoundation/AVFoundation.h>
#import "PZPushMiddleware.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

#define VOIP_TOKEN_STORAGE_KEY @"VOIP-TOKEN"

@interface AppDelegate()
@property (nonatomic, strong) LogInViewController *loginViewController;
@property (nonatomic, strong) CallingViewController *callingViewController;
@property (nonatomic, strong) SIPCallingViewController *sipCallingViewController;
@property (nonatomic, strong) SIPIncomingViewController *sipIncomingViewController;
@end

@implementation AppDelegate

- (void)doRegistrationWithLoginCheck {
    if ([SystemUser currentUser].isLoggedIn) {
        [self registerForVoIPNotifications];
    }
}

#pragma mark - UIApplication delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { 
    [self doRegistrationWithLoginCheck];
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Google Analytics
    [[GAI sharedInstance] trackerWithTrackingId:[[Configuration new] objectInConfigKeyed:@"Tokens", @"Google Analytics", nil]];
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Set an additional dimensionValue for different brands.
    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:1] value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]];

#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
    [GAI sharedInstance].dryRun = YES;    // NOTE: Set to YES to disable tracking
#endif

    [[ConnectionHandler sharedConnectionHandler] start];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Setup appearance
    [self setupAppearance];
    
    // Handler for failed authentications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
    
    /**
     * Menu setup including all its viewControllers.
     */
    SideMenuViewController *sideMenuViewController = [[SideMenuViewController alloc] init];
    
    self.callingViewController = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:[NSBundle mainBundle]];
    self.callingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    self.sipCallingViewController = [[SIPCallingViewController alloc] initWithNibName:@"SIPCallingViewController" bundle:[NSBundle mainBundle]];
    self.sipCallingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    self.sipIncomingViewController = [[SIPIncomingViewController alloc] initWithNibName:@"SIPIncomingViewController" bundle:[NSBundle mainBundle]];
    self.sipIncomingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    ContactsViewController *contactsViewController = [[ContactsViewController alloc] init];
    contactsViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *contactsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:contactsViewController];

    UIViewController *recentsViewController = [[RecentsViewController alloc] initWithNibName:@"RecentsViewController" bundle:[NSBundle mainBundle]];
    recentsViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *recentsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:recentsViewController];
    recentsNavigationViewController.navigationBar.translucent = NO;

    UIViewController *dialerViewController = [[DialerViewController alloc] initWithNibName:@"DialerViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *dialerNavigationController = [[UINavigationController alloc] initWithRootViewController:dialerViewController];
    dialerNavigationController.navigationBar.translucent = NO;

    /**
     * tab bar setup
     */
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.tabBar.translucent = NO;
    self.tabBarController.viewControllers = @[ dialerNavigationController, contactsNavigationViewController,recentsNavigationViewController ];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"]) {
        self.tabBarController.selectedIndex = 1;    // Contacts
    }
    
    /**
     * Left drawer setup.
     */
    MMDrawerController *drawerController = [[MMDrawerController alloc] initWithCenterViewController:self.tabBarController leftDrawerViewController:sideMenuViewController];
    [drawerController setRestorationIdentifier:@"MMDrawer"];
    [drawerController setMaximumLeftDrawerWidth:222.0];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    [drawerController setShadowRadius:2.f];
    [drawerController setShadowOpacity:0.5f];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = drawerController;
    [self.window makeKeyAndVisible];
    
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
    
    NSSetUncaughtExceptionHandler(&HandleExceptions);

    return YES;
}

#pragma mark - VoiP push notifications
- (void)registerForVoIPNotifications {
    if ([SystemUser currentUser].sipEnabled) {
        [[PZPushMiddleware sharedInstance] registerForVoIPNotifications];
    }
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

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    // I (Karsten) have no clue why we're doing this. We are not using these remote notifications.
    // Don't know if PushKit suffers from removing it...
    NSLog(@"Registering device for push notifications..."); // iOS 8
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (application.applicationState != UIApplicationStateActive) { //
        [[ConnectionHandler sharedConnectionHandler] handleLocalNotification:notification withActionIdentifier:nil];
    }
}

#pragma mark - PKPushRegistray management
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    NSLog(@"%s Incomming push notification of type: %@", __PRETTY_FUNCTION__, type);
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    NSDictionary *payloadDict = [payload dictionaryPayload];
    [[PZPushMiddleware sharedInstance] handleReceivedNotificationForApplicationState:state
                                                               payload:payloadDict];
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
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self doRegistrationWithLoginCheck];
}

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

#pragma mark - Handle person(s)
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
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    if ([SystemUser currentUser].sipEnabled &&
        [ConnectionHandler sharedConnectionHandler].connectionStatus == ConnectionStatusHigh &&
        [ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusConnected) {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                              action:@"Outbound"
                                                               label:@"SIP"
                                                               value:nil] build]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.sipCallingViewController handlePhoneNumber:phoneNumber forContact:contact];
        });
    } else {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"call"
                                                              action:@"Outbound"
                                                               label:@"ConnectAB"
                                                               value:nil] build]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.callingViewController handlePhoneNumber:phoneNumber forContact:contact];
        });
    }
}

- (void)handlePhoneNumber:(NSString *)phoneNumber {
    [self handlePhoneNumber:phoneNumber forContact:nil];
}

- (void)handleSipCall:(GSCall *)sipCall {
    return [self.sipCallingViewController handleSipCall:sipCall];
}

#pragma mark - Notification actions
- (void)showOnboarding:(OnboardingScreens)screenToShow {
    // Check if the loginViewController is created, and if present
    NSLog(@"self.loginViewController.presentingViewController %@", self.loginViewController.presentingViewController);
    if (self.loginViewController == nil || !self.loginViewController.presentingViewController) {
        // Create a new instance, and present it.
        self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];
        self.loginViewController.screenToShow = screenToShow;
        self.loginViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        // Set animated to NO to prevent a flip to the login/onboarding view.
        [self.window.rootViewController presentViewController:self.loginViewController animated:YES completion:nil];
    }
}

- (void)loginFailedNotification:(NSNotification *)notification {
    [self showOnboarding:OnboardingScreenLogin];
}

#pragma mark - Private Methods
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

@end
