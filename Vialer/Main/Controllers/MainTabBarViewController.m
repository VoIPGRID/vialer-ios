//
//  MainTabBarViewController.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "MainTabBarViewController.h"
#import "Vialer-Swift.h"

@interface MainTabBarViewController ()

@end

@implementation MainTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)setupLayout {
    ColorsConfiguration *config = [ColorsConfiguration shared];

    // Customize TabBar
    [UITabBar appearance].tintColor = [config colorForKey:ColorsTabBarTint];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setTintColor:[config colorForKey: ColorsTabBarTint]];
    [UITabBar appearance].barTintColor = [config colorForKey: ColorsTabBarBackground];
}

@end
