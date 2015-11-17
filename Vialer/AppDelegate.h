//
//  AppDelegate.h
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>

@class GSCall;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)handleSipCall:(GSCall *)sipCall;

@end
