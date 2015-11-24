//
//  MainTabBarViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 17/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "MainTabBarViewController.h"

@interface MainTabBarViewController ()

@end

@implementation MainTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)setupLayout {
    Configuration *config = [Configuration defaultConfiguration];

    // Customize TabBar
    [UITabBar appearance].tintColor = [config tintColorForKey:ConfigurationTabBarTintColor];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setTintColor:[config tintColorForKey:ConfigurationTabBarTintColor]];
    [UITabBar appearance].barTintColor = [config tintColorForKey:ConfigurationTabBarBackgroundColor];

    // Customize NavigationBar
    [UINavigationBar appearance].tintColor = [config tintColorForKey:ConfigurationNavigationBarTintColor];
    [UINavigationBar appearance].barTintColor = [config tintColorForKey:ConfigurationNavigationBarBarTintColor];
}

@end
