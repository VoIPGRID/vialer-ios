//
//  AppDelegate.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>

@class GSCall;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)handleSipCall:(GSCall *)sipCall;

/**
 * @return YES when the app was started for the purpose of taking screenshots
 */
+ (BOOL)isSnapshotScreenshotRun;

@end
