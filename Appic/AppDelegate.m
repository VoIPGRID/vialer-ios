//
//  AppDelegate.m
//  Appic
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"

#import "VoysRequestOperationManager.h"
#import "LogInViewController.h"
#import "ContactsViewController.h"
#import "RecentsViewController.h"
#import "DashboardViewController.h"

@interface AppDelegate()
@property (nonatomic, strong) LogInViewController *loginViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];

    // Setup appearance
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0xf9 / 255.f green:0xf9 / 255.f blue:0xf9 / 255.f alpha:1.0f]];
        [[UITabBar appearance] setTintColor:[UIColor colorWithRed:0x9b / 255.f green:0xc3 / 255.f blue:0x2f / 255.f alpha:1.f]];
    }

    [[UINavigationBar appearance] setBackgroundColor:[UIColor clearColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage imageNamed:@"nav-bar"] stretchableImageWithLeftCapWidth:20 topCapHeight:10] forBarMetrics:UIBarMetricsDefault];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    } else {
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0x2e / 255.f green:0x31 / 255.f blue:0x92 / 255.f alpha:0.8f]];
    }

    // Handler for failed authentications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailedNotification:) name:LOGIN_FAILED_NOTIFICATION object:nil];
    
    self.loginViewController = [[LogInViewController alloc] initWithNibName:@"LogInViewController" bundle:[NSBundle mainBundle]];
    self.loginViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    ContactsViewController *contactsViewController = [[ContactsViewController alloc] init];
    contactsViewController.view.backgroundColor = [UIColor clearColor];
    contactsViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    
    UIViewController *recentsViewController = [[RecentsViewController alloc] initWithNibName:@"RecentsViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *recentsNavigationViewController = [[UINavigationController alloc] initWithRootViewController:recentsViewController];
    recentsNavigationViewController.view.backgroundColor = [UIColor clearColor];
    recentsNavigationViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;

    UIViewController *dashboardViewController = [[DashboardViewController alloc] initWithNibName:@"DashboardViewController" bundle:[NSBundle mainBundle]];
    UINavigationController *dashboardNavigationViewController = [[UINavigationController alloc] initWithRootViewController:dashboardViewController];
    dashboardNavigationViewController.view.backgroundColor = [UIColor clearColor];
    dashboardNavigationViewController.navigationBar.barStyle = UIStatusBarStyleLightContent;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[recentsNavigationViewController, contactsViewController, dashboardNavigationViewController];
    self.window.rootViewController = self.tabBarController;
    
    [self.window makeKeyAndVisible];

    if (![[VoysRequestOperationManager sharedRequestOperationManager] isLoggedIn]) {
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
