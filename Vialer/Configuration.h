//
//  Configuration.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

@import UIKit;

// Known tint color names
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
extern NSString * const ConfigurationGradientBackgroundColors;
extern NSString * const ConfigurationGradientViewGradientStart;
extern NSString * const ConfigurationGradientViewGradientEnd;
extern NSString * const ConfigurationGradientViewGradientAngle;
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
extern NSString * const ConfigurationMiddleWareBaseURLString;

extern NSString * const ConfigurationPartnerURLKey;

/**
 *  Class for accessing items from Config.plist. As a default the plist from the main bundle is used.
 */
@interface Configuration : NSObject

/**
 * Obtain an instance to this class' Singleton.
 *
 * @return Configuration's singleton instance.
 */
+ (instancetype)defaultConfiguration;

/**
 *  Obtain an NSString containing an URL for the given key.
 *
 *  @param key The key for which to fetch the URL.
 *
 *  @return A NSString containing the URL value.
 */
- (NSString *)UrlForKey:(NSString *)key;

/**
 *  Obtain an UIColor for the key specified.
 *
 *  @param key The key for which to fetch the color.
 *
 *  @return An instance to a UIColor.
 */
- (UIColor *)tintColorForKey:(NSString *)key;

/**
 *  Obtain a dictionary containing UIColor objects for the specified key.
 *
 *  @param key The key for which to fetch the dictionary.
 *
 *  @return A dictionary containing UIColor instances.
 */
- (NSDictionary *)tintColorDictionaryForKey:(NSString *)key;

/**
 *  Method to create an UIColor from the given array.
 *
 *  @param array A NSArray containing 3 elements representing RGB values.
 *
 *  @return An UIColor representing the given RBG color.
 */
+ (UIColor *)colorFromArray:(NSArray *)array;

@end
