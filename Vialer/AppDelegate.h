//
//  AppDelegate.h
//  Vialer
//
//  Created by Reinier Wieringa on 31/10/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

#import <PushKit/PushKit.h>

@class GSCall;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

- (BOOL)handlePerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact;
- (void)handlePhoneNumber:(NSString *)phoneNumber;
- (void)handleSipCall:(GSCall *)sipCall;

- (void)registerForVoIPNotifications;

@end
