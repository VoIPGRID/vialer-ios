//
//  AppDelegate.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const AppDelegateIncomingCallNotification;
extern NSString * const AppDelegateIncomingBackgroundCallNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/**
 *  Core Data Parent Managed Object Context.
 *
 *  Every other object context should be a child context from this context.
 */
@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;
/**
 *  YES if the app was started for the purpose of making screenshots
 */
@property (readonly) BOOL isScreenshotRun;
@end
