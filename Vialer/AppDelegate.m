//
//  AppDelegate.m
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "VoIPGRIDRequestOperationManager.h"
#import "LogInViewController.h"
#import "CallingViewController.h"
#import "SIPCallingViewController.h"
#import "SIPIncomingViewController.h"
#import "ContactsViewController.h"
#import "RecentsViewController.h"
#import "DialerViewController.h"
#import "SettingsViewController.h"
#import "GoToViewController.h"
#import "ConnectionHandler.h"
#import "BackgroundTaskHandler.h"
#import "Gossip+Extra.h"

#import "AFNetworkActivityLogger.h"
#import "UIAlertView+Blocks.h"

#import <AVFoundation/AVFoundation.h>

@interface AppDelegate()
@property (nonatomic, strong) LogInViewController *loginViewController;
@property (nonatomic, strong) CallingViewController *callingViewController;
@property (nonatomic, strong) SIPCallingViewController *sipCallingViewController;
@property (nonatomic, strong) SIPIncomingViewController *sipIncomingViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");

    // New Relic
    NSString *newRelicToken = [[config objectForKey:@"Tokens"] objectForKey:@"New Relic"];
    if ([newRelicToken length]) {
        [NewRelicAgent startWithApplicationToken:newRelicToken];
    }

#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
#endif

    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[ConnectionHandler sharedConnectionHandler] start];

    // Setup appearance
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        NSArray *tabBarColor = [[config objectForKey:@"Tint colors"] objectForKey:@"TabBar"];
        NSAssert(tabBarColor != nil && tabBarColor.count == 3, @"Tint colors - TabBar not found in Config.plist!");
        [[UITabBar appearance] setTintColor:[UIColor colorWithRed:[tabBarColor[0] intValue] / 255.f green:[tabBarColor[1] intValue] / 255.f blue:[tabBarColor[2] intValue] / 255.f alpha:1.f]];
        [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setTintColor:[UIColor colorWithRed:[tabBarColor[0] intValue] / 255.f green:[tabBarColor[1] intValue] / 255.f blue:[tabBarColor[2] intValue] / 255.f alpha:1.f]];
    }

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    [[UINavigationBar appearance] setBackgroundColor:[UIColor clearColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage imageNamed:@"nav-bar"] stretchableImageWithLeftCapWidth:20 topCapHeight:10] forBarMetrics:UIBarMetricsDefault];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    } else {
        NSArray *navigationBarColor = [[config objectForKey:@"Tint colors"] objectForKey:@"NavigationBar"];
        NSAssert(navigationBarColor != nil && navigationBarColor.count == 3, @"Tint colors - NavigationBar not found in Config.plist!");
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:[navigationBarColor[0] intValue] / 255.f green:[navigationBarColor[1] intValue] / 255.f blue:[navigationBarColor[2] intValue] / 255.f alpha:1.f]];
    }

    // Handler for failed authentications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
    
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];
    self.loginViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    self.callingViewController = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:[NSBundle mainBundle]];
    self.callingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    self.sipCallingViewController = [[SIPCallingViewController alloc] initWithNibName:@"SIPCallingViewController" bundle:[NSBundle mainBundle]];
    self.sipCallingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    self.sipIncomingViewController = [[SIPIncomingViewController alloc] initWithNibName:@"SIPIncomingViewController" bundle:[NSBundle mainBundle]];
    self.sipIncomingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    ContactsViewController *contactsViewController = [[ContactsViewController alloc] init];
    contactsViewController.view.backgroundColor = [UIColor clearColor];

    UIViewController *recentsViewController = [[RecentsViewController alloc] initWithNibName:@"RecentsViewController" bundle:[NSBundle mainBundle]];
    recentsViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *recentsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:recentsViewController];
    recentsNavigationViewController.view.backgroundColor = [UIColor clearColor];

    UIViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:[NSBundle mainBundle]];
    settingsViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *settingsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsNavigationViewController.view.backgroundColor = [UIColor clearColor];

    UIViewController *gotoViewController = [[GoToViewController alloc] initWithNibName:@"GoToViewController" bundle:[NSBundle mainBundle]];
    gotoViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *gotoNavigationViewController = [[UINavigationController alloc] initWithRootViewController:gotoViewController];
    gotoNavigationViewController.view.backgroundColor = [UIColor clearColor];
    
    UIViewController *dialerViewController = [[DialerViewController alloc] initWithNibName:@"DialerViewController" bundle:[NSBundle mainBundle]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[recentsNavigationViewController, contactsViewController, dialerViewController, gotoNavigationViewController, settingsNavigationViewController];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"]) {
        self.tabBarController.selectedIndex = 1;    // Contacts
    } else {
        self.tabBarController.selectedIndex = 4;    // Settings
    }
    self.window.rootViewController = self.tabBarController;
    
    [self.window makeKeyAndVisible];

    if ([VoIPGRIDRequestOperationManager isLoggedIn]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                [UIAlertView showWithTitle:NSLocalizedString(@"Microphone Access Denied", nil) message:NSLocalizedString(@"You must allow microphone access in Settings > Privacy > Microphone.", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@[NSLocalizedString(@"Ok", nil)] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex == 1 && UIApplicationOpenSettingsURLString != nil) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }
                }];
            }
        }];
    } else {
        [self showLogin];
    }

    [[ConnectionHandler sharedConnectionHandler] registerForLocalNotifications];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [GSAccount reregisterActiveAccounts];
        });
    }];
    [[BackgroundTaskHandler sharedBackgroundTaskHandler] startBackgroundTask];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[UIApplication sharedApplication] clearKeepAliveTimeout];
    [[BackgroundTaskHandler sharedBackgroundTaskHandler] endAllBackgroundTasks];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (application.applicationState != UIApplicationStateActive) {
        [[ConnectionHandler sharedConnectionHandler] handleLocalNotification:notification withActionIdentifier:nil];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    if (application.applicationState != UIApplicationStateActive) {
        [[ConnectionHandler sharedConnectionHandler] handleLocalNotification:notification withActionIdentifier:identifier];
        if (completionHandler) {
            completionHandler();
        }
    }
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

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
    if ([ConnectionHandler sharedConnectionHandler].connectionStatus == ConnectionStatusHigh &&
        [ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusConnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.sipCallingViewController handlePhoneNumber:phoneNumber forContact:contact];
        });
    } else {
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

#pragma mark - Notifications

- (void)showLogin {
    if (!self.loginViewController.presentingViewController) {
        [self.window.rootViewController presentViewController:self.loginViewController animated:YES completion:nil];
    }
}

- (void)loginFailedNotification:(NSNotification *)notification {
    [self showLogin];
}

@end
