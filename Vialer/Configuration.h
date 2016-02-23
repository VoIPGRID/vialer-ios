//
//  Configuration.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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

/** Generic class for accessing the Config.plist items, default the Config.plist from the main bundle is used.
 If you only need one value, you can access it by the static class functions e.g.

 `[Configuration tintColorForKey:AvailabilityTableViewTintColor];`

 Otherwise create an instance of the configuration and access the member functions.

 Configuration *config = [Configuration defaultConfiguration];
 UIColor *tableColor = [config tintColorForKey:AvailabilityTableViewTintColor];
 UIColor *messagecolor = [config tintColorForKey:ReachabilityBarBackGroundColor];

 */
@interface Configuration : NSObject

/* Dependency Injection */
@property (strong, nonatomic) NSDictionary *dictionary;

+ (instancetype)defaultConfiguration;

/** Generic method to get the UIColor for the specific key
 @param key NSString as the key for the NSArray containing the color configuration
 @result UIColor instance */
- (UIColor *)tintColorForKey:(NSString *)key;

/** Generic method to create the UIColor from given array
 @param array NSArray as the array with 3 values for RGB colors
 @result UIColor instance */
+ (UIColor *)colorFromArray:(NSArray *)array;

/** Generic method to get the Url as NSString for the specific key
 @param key NSString as the key for the URLS Dictionary part
 @result Url NSString instance
 */
- (NSString *)UrlForKey:(NSString *)key;

/**  Class method for easy access to a color
 @see -tintColorForKey:
 */
+ (UIColor *)tintColorForKey:(NSString *)key;

/**  Class method for easy access to a dictionary with colors
 */
+ (NSDictionary *)tintColorDictionaryForKey:(NSString *)key;

/** Class method for easy access to an url
 @see -UrlForKey:
 */
+ (NSString *)UrlForKey:(NSString *)key;

@end
