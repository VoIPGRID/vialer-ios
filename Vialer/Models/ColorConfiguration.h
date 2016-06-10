//
//  ColorConfiguration.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ConfigurationTabBarBackgroundColor;
extern NSString * const ConfigurationTabBarTintColor;
extern NSString * const ConfigurationNavigationBarTintColor;
extern NSString * const ConfigurationNavigationBarBarTintColor;
extern NSString * const ConfigurationConfigTextFieldBorderColor;
extern NSString * const ConfigurationAvailabilityTableViewTintColor;
extern NSString * const ConfigurationReachabilityBarBackgroundColor;
extern NSString * const ConfigurationRecentsTableViewTintColor;
extern NSString * const ConfigurationContactSearchBarBarTintColor;
extern NSString * const ConfigurationContactSearchBarTintColor;
extern NSString * const ConfigurationLeftDrawerButtonTintColor;
extern NSString * const ConfigurationTwoStepScreenBackgroundHeaderColor;
extern NSString * const ConfigurationTwoStepScreenInfoBarBackgroundColor;
extern NSString * const ConfigurationTwoStepScreenBubblingColor;
extern NSString * const ConfigurationTwoStepScreenSideAIconColor;
extern NSString * const ConfigurationTwoStepScreenSideBIconColor;
extern NSString * const ConfigurationTwoStepScreenVialerIconColor;

extern NSString * const ConfigurationBackgroundGradientStartColor;
extern NSString * const ConfigurationBackgroundGradientEndColor;
extern CGFloat const ConfigurationBackgroundGradientAngle;

extern NSString * const ConfigurationSideMenuTintColor;
extern NSString * const ConfigurationSideMenuButtonPressedState;
extern NSString * const ConfigurationRecentsSegmentedControlTintColor;
extern NSString * const ConfigurationContactsTableSectionIndexColor;
extern NSString * const ConfigurationNumberPadButtonTextColor;
extern NSString * const ConfigurationNumberPadButtonPressedColor;
extern NSString * const ConfigurationRecentsFilterControlTintColor;
extern NSString * const ConfigurationLogInViewControllerButtonBorderColor;
extern NSString * const ConfigurationLogInViewControllerButtonBackgroundColorForPressedState;
extern NSString * const ConfigurationActivateSIPAccountViewControllerButtonBorderColor;
extern NSString * const ConfigurationActivateSIPAccountViewControllerButtonBackgroundColorForPressedState;
extern NSString * const ConfigurationSideMenuHeaderBackgroundColor;

/**
 This class represents the color configuration as defined in the Config.plist.
 */
@interface ColorConfiguration : NSObject
/**
 *  This initializer is not to be used.
 */
- (instancetype)init __attribute__((unavailable("init not available")));

/**
 *  This is the designated initializer for this class. Do not use init.
 *
 *  @param configPlist A NSDictionary representing the contents of the Config.plist file.
 *
 *  @return An ColorConfiguration instance.
 */
- (instancetype)initWithConfigPlist:(NSDictionary *)configPlist NS_DESIGNATED_INITIALIZER;

/**
 *  Obtain an UIColor for the key specified.
 *
 *  @param key The key for which to fetch the color.
 *
 *  @return An instance to a UIColor.
 */
- (UIColor *)colorForKey:(NSString *)key;

@end
