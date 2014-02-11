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
#import "ContactsViewController.h"
#import "RecentsViewController.h"
#import "DashboardViewController.h"
#import "DialerViewController.h"
#import "SettingsViewController.h"

#import "TestFlight.h"
#import "AFNetworkActivityLogger.h"

#import <NewRelicAgent/NewRelic.h>

@interface AppDelegate()
@property (nonatomic, strong) LogInViewController *loginViewController;
@property (nonatomic, strong) CallingViewController *callingViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");

    // Test flight
    NSString *testFlightToken = [[config objectForKey:@"Tokens"] objectForKey:@"Test Flight"];
    if ([testFlightToken length]) {
        [TestFlight takeOff:[[config objectForKey:@"Tokens"] objectForKey:@"Test Flight"]];
    }

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

    // Setup appearance
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        NSArray *tabBarColor = [[config objectForKey:@"Tint colors"] objectForKey:@"TabBar"];
        NSAssert(tabBarColor != nil && tabBarColor.count == 3, @"Tint colors - TabBar not found in Config.plist!");
        [[UITabBar appearance] setTintColor:[UIColor colorWithRed:[tabBarColor[0] intValue] / 255.f green:[tabBarColor[1] intValue] / 255.f blue:[tabBarColor[2] intValue] / 255.f alpha:1.f]];
    }

    [[UINavigationBar appearance] setBackgroundColor:[UIColor clearColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor whiteColor]}];
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

    ContactsViewController *contactsViewController = [[ContactsViewController alloc] init];
    contactsViewController.view.backgroundColor = [UIColor clearColor];
    contactsViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    
    UIViewController *recentsViewController = [[RecentsViewController alloc] initWithNibName:@"RecentsViewController" bundle:[NSBundle mainBundle]];
    recentsViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *recentsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:recentsViewController];
    recentsNavigationViewController.view.backgroundColor = [UIColor clearColor];
    recentsNavigationViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;

    UIViewController *dashboardViewController = [[DashboardViewController alloc] initWithNibName:@"DashboardViewController" bundle:[NSBundle mainBundle]];
    dashboardViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *dashboardNavigationViewController = [[UINavigationController alloc] initWithRootViewController:dashboardViewController];
    dashboardNavigationViewController.view.backgroundColor = [UIColor clearColor];
    dashboardNavigationViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;

    UIViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:[NSBundle mainBundle]];
    settingsViewController.view.backgroundColor = [UIColor clearColor];
    UINavigationController *settingsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsNavigationViewController.view.backgroundColor = [UIColor clearColor];
    settingsNavigationViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    
    UIViewController *dialerViewController = [[DialerViewController alloc] initWithNibName:@"DialerViewController" bundle:[NSBundle mainBundle]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[recentsNavigationViewController, contactsViewController, dialerViewController, settingsNavigationViewController];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"MobileNumber"]) {
        self.tabBarController.selectedIndex = 1;    // Contacts
    } else {
        self.tabBarController.selectedIndex = 3;    // Settings
    }
    self.window.rootViewController = self.tabBarController;
    
    [self.window makeKeyAndVisible];

    if (![[VoIPGRIDRequestOperationManager sharedRequestOperationManager] isLoggedIn]) {
        [self showLogin];
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    return [self.callingViewController handlePerson:person property:property identifier:identifier];
}

- (void)handlePhoneNumber:(NSString *)phoneNumber {
    return [self.callingViewController handlePhoneNumber:phoneNumber forContact:nil];
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
